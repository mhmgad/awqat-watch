import { DayTimetable, MosqueChoice, PrayerRow } from '../model/Models';
import { asArray, asObject, boolVal, strVal } from './JsonUtil';
import { MawaqitApi } from './MawaqitApi';

const DISPLAY: Record<string, string> = {
  'fajr': 'Fajr',
  'dhuhr': 'Dhuhr',
  'jumua': 'Jumua',
  'asr': 'Asr',
  'maghrib': 'Maghrib',
  'isha': 'Isha'
};

export class TimetableService {
  private api: MawaqitApi = new MawaqitApi();

  async load(mosque: MosqueChoice): Promise<DayTimetable> {
    const page = await this.api.fetchMosque(mosque.code);
    const conf = page.conf;
    const now = new Date();
    const clocks = this.clocksFromConf(conf, now);
    mosque.label = page.choice.label || mosque.label;
    return this.toTimetable(mosque, conf, clocks, now);
  }

  private clocksFromConf(conf: Record<string, Object>, now: Date): Record<string, string> {
    const clocks: Record<string, string> = {
      'fajr': '--:--',
      'dhuhr': '--:--',
      'asr': '--:--',
      'maghrib': '--:--',
      'isha': '--:--',
      'jumua': '--:--'
    };
    const row = this.todayRow(conf, now);
    if (row.length >= 6) {
      const offset = row.length === 7 ? 1 : 0;
      clocks['fajr'] = row[offset];
      clocks['dhuhr'] = row[offset + 2];
      clocks['asr'] = row[offset + 3];
      clocks['maghrib'] = row[offset + 4];
      clocks['isha'] = row[offset + 5];
    } else {
      const times = stringRow(conf['times']);
      if (times.length >= 5) {
        clocks['fajr'] = times[0];
        clocks['dhuhr'] = times[1];
        clocks['asr'] = times[2];
        clocks['maghrib'] = times[3];
        clocks['isha'] = times[4];
      }
    }
    if (boolVal(conf, 'jumuaAsDuhr')) {
      clocks['jumua'] = clocks['dhuhr'];
    } else {
      clocks['jumua'] = strVal(conf, 'jumua', clocks['dhuhr']);
    }
    return clocks;
  }

  private todayRow(conf: Record<string, Object>, now: Date): string[] {
    const calendar = asArray(conf['calendar']);
    if (calendar.length < 12) {
      return [];
    }
    const month = asObject(calendar[now.getMonth()]);
    return stringRow(month[`${now.getDate()}`]);
  }

  private toTimetable(
    mosque: MosqueChoice,
    conf: Record<string, Object>,
    clocks: Record<string, string>,
    now: Date
  ): DayTimetable {
    const friday = now.getDay() === 5;
    const names = friday ?
      ['fajr', 'jumua', 'asr', 'maghrib', 'isha'] :
      ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const table = new DayTimetable();
    table.mosqueLabel = mosque.label;
    table.method = 'Mawaqit';

    let nextName = names[0];
    let nextClock = clocks[names[0]];
    let nextAt = this.clockToDate(clocks[names[0]], now, true);
    for (let i = 0; i < names.length; i++) {
      const name = names[i];
      const at = this.clockToDate(clocks[name], now, false);
      if (at.getTime() > now.getTime()) {
        nextName = name;
        nextClock = clocks[name];
        nextAt = at;
        break;
      }
    }
    if (nextAt.getTime() <= now.getTime()) {
      const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
      nextName = 'fajr';
      nextClock = clocks['fajr'];
      nextAt = this.clockToDate(clocks['fajr'], tomorrow, false);
    }

    for (let i = 0; i < names.length; i++) {
      const name = names[i];
      const row = new PrayerRow();
      row.name = name;
      row.displayName = DISPLAY[name] ?? name;
      row.clock = clocks[name] ?? '--:--';
      row.isNext = name === nextName;
      table.rows.push(row);
    }
    table.nextName = DISPLAY[nextName] ?? nextName;
    table.nextClock = nextClock;
    table.nextAtMs = nextAt.getTime();
    return table;
  }

  private clockToDate(clock: string, day: Date, nextDayIfPast: boolean): Date {
    const parts = clock.split(':');
    const hours = Number(parts[0] ?? '0');
    const minutes = Number(parts[1] ?? '0');
    const result = new Date(day.getFullYear(), day.getMonth(), day.getDate(), hours, minutes, 0, 0);
    if (nextDayIfPast && result.getTime() <= Date.now()) {
      result.setDate(result.getDate() + 1);
    }
    return result;
  }
}

function stringRow(value: Object | string | number | boolean | null | undefined): string[] {
  const items = asArray(value);
  const out: string[] = [];
  for (let i = 0; i < items.length; i++) {
    out.push(`${items[i]}`);
  }
  return out;
}
