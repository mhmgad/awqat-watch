/**
 * Compact PrayTimes port (PrayTimes.org, GNU LGPL v3.0) for watch use.
 */
export class PrayTimes {
  private settings: Record<string, string> = {
    'imsak': '10 min',
    'fajr': '18',
    'dhuhr': '0 min',
    'asr': 'Standard',
    'sunset': '0.833',
    'maghrib': '0 min',
    'isha': '17',
    'midnight': 'Standard',
    'highLats': 'NightMiddle'
  };
  private lat: number = 0;
  private lng: number = 0;
  private timeZone: number = 0;
  private jDate: number = 0;

  setMethod(method: string): void {
    const methods: Record<string, number[]> = {
      'MWL': [18, 17],
      'ISNA': [15, 15],
      'Egypt': [19.5, 17.5],
      'Makkah': [18.5, 90],
      'Karachi': [18, 18],
      'Tehran': [17.7, 14],
      'Jafari': [16, 14],
      'UOIF': [12, 12]
    };
    const pair = methods[method] ?? methods['MWL'];
    this.settings['fajr'] = `${pair[0]}`;
    if (method === 'Makkah') {
      this.settings['isha'] = '90 min';
    } else {
      this.settings['isha'] = `${pair[1]}`;
    }
  }

  setAngle(name: string, angle: string): void {
    this.settings[name] = angle;
  }

  getTimes(year: number, month: number, day: number, lat: number, lng: number, tz: number): Record<string, string> {
    this.lat = lat;
    this.lng = lng;
    this.timeZone = tz;
    this.jDate = this.julian(year, month, day) - lng / (15 * 24);
    let times: Record<string, number> = {
      'imsak': 5,
      'fajr': 5,
      'sunrise': 6,
      'dhuhr': 12,
      'asr': 13,
      'sunset': 18,
      'maghrib': 18,
      'isha': 18
    };
    times = this.computePrayerTimes(times);
    times = this.adjustTimes(times);
    const result: Record<string, string> = {};
    const names = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (let i = 0; i < names.length; i++) {
      result[names[i]] = this.formatTime(times[names[i]]);
    }
    return result;
  }

  private computePrayerTimes(times: Record<string, number>): Record<string, number> {
    const dayTimes: Record<string, number> = {};
    const keys = Object.keys(times);
    for (let i = 0; i < keys.length; i++) {
      dayTimes[keys[i]] = times[keys[i]] / 24;
    }
    return {
      'imsak': this.sunAngleTime(this.evalNum(this.settings['imsak']), dayTimes['imsak'], true),
      'fajr': this.sunAngleTime(this.evalNum(this.settings['fajr']), dayTimes['fajr'], true),
      'sunrise': this.sunAngleTime(0.833, dayTimes['sunrise'], true),
      'dhuhr': this.midDay(dayTimes['dhuhr']),
      'asr': this.asrTime(dayTimes['asr']),
      'sunset': this.sunAngleTime(0.833, dayTimes['sunset'], false),
      'maghrib': this.sunAngleTime(this.evalNum(this.settings['maghrib']), dayTimes['maghrib'], false),
      'isha': this.sunAngleTime(this.evalNum(this.settings['isha']), dayTimes['isha'], false)
    };
  }

  private adjustTimes(times: Record<string, number>): Record<string, number> {
    const tzAdjust = this.timeZone - this.lng / 15;
    const adjusted: Record<string, number> = {};
    const keys = Object.keys(times);
    for (let i = 0; i < keys.length; i++) {
      adjusted[keys[i]] = times[keys[i]] + tzAdjust;
    }
    if (this.isMin(this.settings['imsak'])) {
      adjusted['imsak'] = adjusted['fajr'] - this.evalNum(this.settings['imsak']) / 60;
    }
    if (this.isMin(this.settings['maghrib'])) {
      adjusted['maghrib'] = adjusted['sunset'] + this.evalNum(this.settings['maghrib']) / 60;
    }
    if (this.isMin(this.settings['isha'])) {
      adjusted['isha'] = adjusted['maghrib'] + this.evalNum(this.settings['isha']) / 60;
    }
    return adjusted;
  }

  private midDay(time: number): number {
    const eqt = this.sunPosition(this.jDate + time)[1];
    return this.fixHour(12 - eqt);
  }

  private sunAngleTime(angle: number, time: number, ccw: boolean): number {
    const decl = this.sunPosition(this.jDate + time)[0];
    const noon = this.midDay(time);
    const cosArg = (-this.sin(angle) - this.sin(decl) * this.sin(this.lat)) /
      (this.cos(decl) * this.cos(this.lat));
    if (cosArg < -1 || cosArg > 1) {
      return Number.NaN;
    }
    const t = (1 / 15) * this.arccos(cosArg);
    return noon + (ccw ? -t : t);
  }

  private asrTime(time: number): number {
    const decl = this.sunPosition(this.jDate + time)[0];
    const factor = this.settings['asr'] === 'Hanafi' ? 2 : 1;
    const angle = -this.arccot(factor + this.tan(Math.abs(this.lat - decl)));
    return this.sunAngleTime(angle, time, false);
  }

  private sunPosition(jd: number): number[] {
    const d = jd - 2451545;
    const g = this.fixAngle(357.529 + 0.98560028 * d);
    const q = this.fixAngle(280.459 + 0.98564736 * d);
    const l = this.fixAngle(q + 1.915 * this.sin(g) + 0.020 * this.sin(2 * g));
    const e = 23.439 - 0.00000036 * d;
    const ra = this.arctan2(this.cos(e) * this.sin(l), this.cos(l)) / 15;
    const eqt = q / 15 - this.fixHour(ra);
    const decl = this.arcsin(this.sin(e) * this.sin(l));
    return [decl, eqt];
  }

  private julian(year: number, month: number, day: number): number {
    let y = year;
    let m = month;
    if (m <= 2) {
      y -= 1;
      m += 12;
    }
    const a = Math.floor(y / 100);
    const b = 2 - a + Math.floor(a / 4);
    return Math.floor(365.25 * (y + 4716)) + Math.floor(30.6001 * (m + 1)) + day + b - 1524.5;
  }

  private formatTime(value: number): string {
    if (Number.isNaN(value)) {
      return '--:--';
    }
    const fixed = this.fixHour(value + 0.5 / 60);
    const hours = Math.floor(fixed);
    const minutes = Math.floor((fixed - hours) * 60);
    return `${this.pad(hours)}:${this.pad(minutes)}`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private evalNum(value: string): number {
    const match = value.match(/[-+]?\d*\.?\d+/);
    return match ? Number(match[0]) : 0;
  }

  private isMin(value: string): boolean {
    return value.indexOf('min') >= 0;
  }

  private sin(deg: number): number {
    return Math.sin(deg * Math.PI / 180);
  }

  private cos(deg: number): number {
    return Math.cos(deg * Math.PI / 180);
  }

  private tan(deg: number): number {
    return Math.tan(deg * Math.PI / 180);
  }

  private arcsin(value: number): number {
    return Math.asin(value) * 180 / Math.PI;
  }

  private arccos(value: number): number {
    return Math.acos(value) * 180 / Math.PI;
  }

  private arccot(value: number): number {
    return Math.atan(1 / value) * 180 / Math.PI;
  }

  private arctan2(y: number, x: number): number {
    return Math.atan2(y, x) * 180 / Math.PI;
  }

  private fixAngle(angle: number): number {
    return this.fix(angle, 360);
  }

  private fixHour(hour: number): number {
    return this.fix(hour, 24);
  }

  private fix(value: number, mode: number): number {
    if (Number.isNaN(value)) {
      return value;
    }
    let result = value - mode * Math.floor(value / mode);
    if (result < 0) {
      result += mode;
    }
    return result;
  }
}
