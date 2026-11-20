import { router } from '@kit.ArkUI';
import { DayTimetable, PrayerRow } from '../model/Models';
import { MosqueStore } from '../service/MosqueStore';
import { TimetableService } from '../service/Timetable';

@Entry
@Component
struct Index {
  @State mosqueLabel: string = '';
  @State loading: boolean = true;
  @State errorText: string = '';
  @State nextName: string = '';
  @State nextClock: string = '';
  @State countdown: string = '--:--:--';
  @State rows: PrayerRow[] = [];
  private timerId: number = -1;
  private nextAtMs: number = 0;
  private loader: TimetableService = new TimetableService();

  aboutToAppear(): void {
    this.timerId = setInterval(() => {
      this.countdown = this.formatCountdown(this.nextAtMs);
    }, 1000);
  }

  aboutToDisappear(): void {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    this.errorText = '';
    try {
      const mosque = await MosqueStore.load();
      if (!mosque) {
        this.mosqueLabel = '';
        this.rows = [];
        this.nextName = '';
        this.loading = false;
        return;
      }
      const table: DayTimetable = await this.loader.load(mosque);
      this.mosqueLabel = table.mosqueLabel;
      this.rows = table.rows;
      this.nextName = table.nextName;
      this.nextClock = table.nextClock;
      this.nextAtMs = table.nextAtMs;
      this.countdown = this.formatCountdown(this.nextAtMs);
    } catch (_err) {
      this.errorText = 'Could not load times';
    } finally {
      this.loading = false;
    }
  }

  private formatCountdown(targetMs: number): string {
    if (!targetMs) {
      return '--:--:--';
    }
    let remaining = Math.max(0, Math.floor((targetMs - Date.now()) / 1000));
    const hours = Math.floor(remaining / 3600);
    remaining -= hours * 3600;
    const minutes = Math.floor(remaining / 60);
    const seconds = remaining - minutes * 60;
    return `${this.pad(hours)}:${this.pad(minutes)}:${this.pad(seconds)}`;
  }

  private pad(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  private openSearch(): void {
    router.pushUrl({ url: 'pages/SearchPage' }).then(() => {
    }).catch(() => {
    });
  }

  onPageShow(): void {
    this.refresh();
  }

  build() {
    Column() {
      if (this.loading) {
        Text($r('app.string.loading'))
          .fontSize(16)
          .fontColor($r('app.color.text_primary'))
      } else if (!this.mosqueLabel) {
        Column() {
          Text('Awqat')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.accent'))
          Text($r('app.string.choose_mosque'))
            .fontSize(14)
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: 8, bottom: 16 })
          Button($r('app.string.search'))
            .onClick(() => {
              this.openSearch();
            })
        }
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll() {
          Column() {
            Text(this.mosqueLabel)
              .fontSize(11)
              .fontColor($r('app.color.text_secondary'))
              .maxLines(2)
              .textAlign(TextAlign.Center)
              .padding({ left: 18, right: 18 })
              .onClick(() => {
                this.openSearch();
              })

            Text(this.nextName)
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.accent'))
              .margin({ top: 8 })

            Text(this.nextClock)
              .fontSize(28)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))

            Text(this.countdown)
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 10 })

            if (this.errorText) {
              Text(this.errorText)
                .fontSize(12)
                .fontColor($r('app.color.accent'))
                .margin({ bottom: 8 })
            }

            ForEach(this.rows, (row: PrayerRow) => {
              Row() {
                Text(row.displayName)
                  .fontSize(13)
                  .fontColor(row.isNext ? $r('app.color.accent') : $r('app.color.text_primary'))
                  .layoutWeight(1)
                Text(row.clock)
                  .fontSize(13)
                  .fontColor(row.isNext ? $r('app.color.accent') : $r('app.color.text_primary'))
              }
              .width('78%')
              .padding({ top: 3, bottom: 3 })
            }, (row: PrayerRow) => row.name)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .padding({ top: 18, bottom: 28 })
        }
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Center)
    .padding({ left: 8, right: 8 })
  }
}
