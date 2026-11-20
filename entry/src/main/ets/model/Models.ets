export class MosqueChoice {
  code: string = '';
  label: string = '';
  alias: string = '';
}

export class PrayerRow {
  name: string = '';
  displayName: string = '';
  clock: string = '--:--';
  isNext: boolean = false;
}

export class DayTimetable {
  mosqueLabel: string = '';
  method: string = '';
  rows: PrayerRow[] = [];
  nextName: string = '';
  nextClock: string = '--:--';
  nextAtMs: number = 0;
}
