import http from '@ohos.net.http';
import { MosqueChoice } from '../model/Models';
import { parseObject } from './JsonUtil';

const PAGE_BASE = 'https://mawaqit.net/en';

export class MawaqitApiError extends Error {
  constructor(message: string) {
    super(message);
  }
}

export class MosquePage {
  slug: string = '';
  choice: MosqueChoice = new MosqueChoice();
  conf: Record<string, Object> = {};
}

export class MawaqitApi {
  async searchMosques(query: string): Promise<MosqueChoice[]> {
    const slugs = slugCandidates(query);
    const found: MosqueChoice[] = [];
    const seen: Record<string, boolean> = {};
    for (let i = 0; i < slugs.length; i++) {
      const slug = slugs[i];
      if (seen[slug]) {
        continue;
      }
      seen[slug] = true;
      try {
        const page = await this.fetchMosque(slug);
        found.push(page.choice);
      } catch (_err) {
        continue;
      }
    }
    return found;
  }

  async fetchMosque(slug: string): Promise<MosquePage> {
    const html = await this.getText(`${PAGE_BASE}/${encodeURIComponent(slug)}`);
    const conf = extractConfData(html);
    if (Object.keys(conf).length === 0) {
      throw new MawaqitApiError(`No Mawaqit timetable for ${slug}`);
    }
    const page = new MosquePage();
    page.slug = slug;
    page.conf = conf;
    page.choice.code = slug;
    page.choice.alias = slug;
    const name = `${conf['name'] ?? ''}`;
    const label = `${conf['label'] ?? ''}`;
    page.choice.label = label || name || slug;
    return page;
  }

  private async getText(url: string): Promise<string> {
    const client = http.createHttp();
    try {
      const response = await client.request(url, {
        method: http.RequestMethod.GET,
        header: {
          'Accept': 'text/html,application/json',
          'User-Agent': 'AwqatWatch/1.0'
        },
        connectTimeout: 15000,
        readTimeout: 20000,
        expectDataType: http.HttpDataType.STRING
      });
      if (response.responseCode >= 400) {
        throw new MawaqitApiError(`HTTP ${response.responseCode} for ${url}`);
      }
      return `${response.result}`;
    } catch (err) {
      if (err instanceof MawaqitApiError) {
        throw err;
      }
      throw new MawaqitApiError(`Request failed for ${url}`);
    } finally {
      client.destroy();
    }
  }
}

export function slugCandidates(query: string): string[] {
  const trimmed = query.trim();
  const fromUrl = slugFromMawaqitUrl(trimmed);
  const raw = fromUrl || trimmed;
  const slug = slugify(raw);
  const out: string[] = [];
  if (slug) {
    out.push(slug);
  }
  return out;
}

function slugFromMawaqitUrl(text: string): string {
  const marker = 'mawaqit.net/';
  const idx = text.indexOf(marker);
  if (idx < 0) {
    return '';
  }
  let rest = text.substring(idx + marker.length);
  const queryAt = rest.indexOf('?');
  if (queryAt >= 0) {
    rest = rest.substring(0, queryAt);
  }
  const parts = rest.split('/');
  if (parts.length >= 3 && parts[1] === 'm') {
    return parts[2];
  }
  if (parts.length >= 2) {
    return parts[1];
  }
  return '';
}

function slugify(value: string): string {
  let text = foldAccents(value.trim().toLowerCase());
  text = text.replace(/[^a-z0-9]+/g, '-');
  text = text.replace(/^-+|-+$/g, '');
  return text;
}

function foldAccents(value: string): string {
  const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
  const to = 'aaaaaaeeeeiiiiooooouuuucn';
  let out = '';
  for (let i = 0; i < value.length; i++) {
    const ch = value.charAt(i);
    const at = from.indexOf(ch);
    out += at >= 0 ? to.charAt(at) : ch;
  }
  return out;
}

export function extractConfData(html: string): Record<string, Object> {
  const marker = 'confData';
  const idx = html.indexOf(marker);
  if (idx < 0) {
    return {};
  }
  const start = html.indexOf('{', idx);
  if (start < 0) {
    return {};
  }
  let depth = 0;
  let inString = false;
  let escape = false;
  let quote = '';
  for (let i = start; i < html.length; i++) {
    const ch = html.charAt(i);
    if (inString) {
      if (escape) {
        escape = false;
      } else if (ch === '\\') {
        escape = true;
      } else if (ch === quote) {
        inString = false;
      }
      continue;
    }
    if (ch === '"' || ch === '\'') {
      inString = true;
      quote = ch;
      continue;
    }
    if (ch === '{') {
      depth += 1;
    } else if (ch === '}') {
      depth -= 1;
      if (depth === 0) {
        return parseObject(html.substring(start, i + 1));
      }
    }
  }
  return {};
}
