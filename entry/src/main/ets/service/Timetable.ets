import { DayTimetable, MosqueChoice, PrayerRow } from '../model/Models';
import { AwqatApi } from './AwqatApi';
import { asArray, asObject, boolVal, numVal, strVal } from './JsonUtil';
import { PrayTimes } from './PrayTimes';

const DISPLAY: Record<string, string> = {
  'fajr': 'Fajr',
  'dhuhr': 'Dhuhr',
  'jumua': 'Jumua',
  'asr': 'Asr',
  'maghrib': 'Maghrib',
  'isha': 'Isha'
};

const CALENDAR_ORDER: string[] = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];

export class TimetableService {
  private api: AwqatApi = new AwqatApi();

  async load(mosque: MosqueChoice): Promise<DayTimetable> {
    const packed = await this.api.fetchConfig(mosque);
    const cfg = asObject(packed['cfg']);
    const calendar = await this.api.fetchCalendar(mosque.code);
    const now = new Date();
    const clocks = this.clocksForDay(cfg, calendar, now);
    return this.toTimetable(mosque, cfg, clocks, now);
  }

  private clocksForDay(
    cfg: Record<string, Object>,
    calendar: Record<string, string[]>,
    now: Date
  ): Record<string, string> {
    const geo = asObject(cfg['geoPlace']);
    const timeSetting = asObject(cfg['timeSetting']);
    const settings = asObject(timeSetting['timeItemSettings']);
    const method = strVal(timeSetting, 'method', 'UOIF');
    const lat = numVal(geo, 'lat');
    const lng = numVal(geo, 'long', numVal(geo, 'lng'));
    const tzHours = -now.getTimezoneOffset() / 60;
    const calculator = new PrayTimes();
    calculator.setMethod(method);
    const fajrSetting = asObject(settings['fajr']);
    const ishaSetting = asObject(settings['isha']);
    if (method === 'CUSTOM' && strVal(fajrSetting, 'angle')) {
      calculator.setAngle('fajr', strVal(fajrSetting, 'angle'));
    }
    if (method === 'CUSTOM' && strVal(ishaSetting, 'angle')) {
      calculator.setAngle('isha', strVal(ishaSetting, 'angle'));
    }
    const computed = calculator.getTimes(now.getFullYear(), now.getMonth() + 1, now.getDate(), lat, lng, tzHours);
    const clocks: Record<string, string> = {
      'fajr': computed['fajr'],
      'dhuhr': computed['dhuhr'],
      'asr': computed['asr'],
      'maghrib': computed['maghrib'],
      'isha': computed['isha']
    };

    if (boolVal(timeSetting, 'useCal')) {
      const key = this.calendarKey(now);
      const row = calendar[key];
      if (row && row.length >= 6) {
        for (let i = 0; i < CALENDAR_ORDER.length; i++) {
          const name = CALENDAR_ORDER[i];
          if (name !== 'sunrise') {
            clocks[name] = row[i];
          }
        }
      }
    }

    clocks['dhuhr'] = this.applyFixed(clocks['dhuhr'], asObject(settings['dhuhr']), now);
    clocks['jumua'] = this.applyFixed(clocks['dhuhr'], asObject(settings['jumua']), now);
    clocks['fajr'] = this.applyFixed(clocks['fajr'], asObject(settings['fajr']), now);
    clocks['asr'] = this.applyFixed(clocks['asr'], asObject(settings['asr']), now);
    clocks['maghrib'] = this.applyFixed(clocks['maghrib'], asObject(settings['maghrib']), now);
    clocks['isha'] = this.applyFixed(clocks['isha'], asObject(settings['isha']), now);
    return clocks;
  }

  private toTimetable(
    mosque: MosqueChoice,
    cfg: Record<string, Object>,
    clocks: Record<string, string>,
    now: Date
  ): DayTimetable {
    const timeSetting = asObject(cfg['timeSetting']);
    const friday = now.getDay() === 5;
    const names = friday ?
      ['fajr', 'jumua', 'asr', 'maghrib', 'isha'] :
      ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    const table = new DayTimetable();
    table.mosqueLabel = mosque.label;
    table.method = strVal(timeSetting, 'method', 'UOIF');

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

  private applyFixed(current: string, setting: Record<string, Object>, now: Date): string {
    const fixedTimes = asArray(setting['fixedTimes']);
    if (fixedTimes.length === 0) {
      return current;
    }
    const dst = this.isDst(now);
    for (let i = 0; i < fixedTimes.length; i++) {
      const item = asObject(fixedTimes[i]);
      const raw = strVal(item, 'time');
      if (raw.length < 4) {
        continue;
      }
      const kind = strVal(item, 'type');
      if (kind === 'dst_yes' && !dst) {
        continue;
      }
      if (kind === 'dst_no' && dst) {
        continue;
      }
      return `${raw.substring(0, 2)}:${raw.substring(2, 4)}`;
    }
    return current;
  }

  private calendarKey(now: Date): string {
    const day = now.getDate();
    const month = now.getMonth() + 1;
    const dd = day < 10 ? `0${day}` : `${day}`;
    const mm = month < 10 ? `0${month}` : `${month}`;
    return `${dd}/${mm}`;
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

  private isDst(now: Date): boolean {
    const jan = new Date(now.getFullYear(), 0, 1).getTimezoneOffset();
    const jul = new Date(now.getFullYear(), 6, 1).getTimezoneOffset();
    return Math.min(jan, jul) === now.getTimezoneOffset() && jan !== jul;
  }
}
