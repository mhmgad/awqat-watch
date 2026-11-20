import http from '@ohos.net.http';
import { MosqueChoice } from '../model/Models';
import { asArray, asObject, parseObject, strVal } from './JsonUtil';

const API_BASE = 'https://widget.fawzone.net';
const WIDGET_TYPE = 'salat-widget';
const CALENDAR_SINCE = '2001-06-30T23:38:13.754Z';

export class AwqatApiError extends Error {
  constructor(message: string) {
    super(message);
  }
}

export class AwqatApi {
  async searchMosques(query: string): Promise<MosqueChoice[]> {
    const encoded = encodeURIComponent(query.trim());
    const payload = await this.getJson(
      `${API_BASE}/widget/findWidgets?label=${encoded}&type=${WIDGET_TYPE}`
    );
    const hits = asArray(payload['result']);
    const mosques: MosqueChoice[] = [];
    for (let i = 0; i < hits.length; i++) {
      const item = asObject(hits[i]);
      const choice = new MosqueChoice();
      choice.code = strVal(item, 'code');
      choice.label = strVal(item, 'label', choice.code);
      choice.alias = strVal(item, 'alias', choice.code);
      if (choice.code) {
        mosques.push(choice);
      }
    }
    return mosques;
  }

  async fetchConfig(mosque: MosqueChoice): Promise<Record<string, Object>> {
    const body = JSON.stringify({
      'code': mosque.code,
      'alias': mosque.alias || mosque.code
    });
    const payload = await this.postJson(`${API_BASE}/widget/findCfg`, body);
    const result = asObject(payload['result']);
    const cfg = asObject(result['cfg']);
    if (Object.keys(cfg).length === 0) {
      throw new AwqatApiError(`No timetable config for ${mosque.code}`);
    }
    result['cfg'] = cfg;
    return result;
  }

  async fetchCalendar(mosqueCode: string): Promise<Record<string, string[]>> {
    const path = `${API_BASE}/awqatCal/byCode/${encodeURIComponent(mosqueCode)}/${CALENDAR_SINCE}`;
    try {
      const payload = await this.getJson(path);
      const result = asObject(payload['result']);
      const value = asObject(result['value']);
      const awqat = asObject(value['awqat']);
      const calendar: Record<string, string[]> = {};
      const keys = Object.keys(awqat);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const row = asArray(awqat[key]);
        const clocks: string[] = [];
        for (let j = 0; j < row.length; j++) {
          clocks.push(`${row[j]}`);
        }
        calendar[key] = clocks;
      }
      return calendar;
    } catch (_err) {
      return {};
    }
  }

  private async getJson(url: string): Promise<Record<string, Object>> {
    return this.request(url, http.RequestMethod.GET, '');
  }

  private async postJson(url: string, body: string): Promise<Record<string, Object>> {
    return this.request(url, http.RequestMethod.POST, body);
  }

  private async request(url: string, method: http.RequestMethod, body: string): Promise<Record<string, Object>> {
    const client = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: method,
        header: {
          'Content-Type': 'application/json',
          'Accept': 'application/json'
        },
        connectTimeout: 15000,
        readTimeout: 15000,
        expectDataType: http.HttpDataType.STRING
      };
      if (body) {
        options.extraData = body;
      }
      const response = await client.request(url, options);
      if (response.responseCode >= 400) {
        throw new AwqatApiError(`HTTP ${response.responseCode} for ${url}`);
      }
      return parseObject(`${response.result}`);
    } catch (err) {
      if (err instanceof AwqatApiError) {
        throw err;
      }
      throw new AwqatApiError(`Request failed for ${url}`);
    } finally {
      client.destroy();
    }
  }
}
