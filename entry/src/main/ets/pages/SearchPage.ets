import { router } from '@kit.ArkUI';
import { MosqueChoice } from '../model/Models';
import { MawaqitApi } from '../service/MawaqitApi';
import { MosqueStore } from '../service/MosqueStore';

@Component
struct SearchPage {
  @State query: string = '';
  @State loading: boolean = false;
  @State errorText: string = '';
  @State results: MosqueChoice[] = [];
  private api: MawaqitApi = new MawaqitApi();

  private async search(): Promise<void> {
    if (!this.query.trim()) {
      return;
    }
    this.loading = true;
    this.errorText = '';
    try {
      this.results = await this.api.searchMosques(this.query);
      if (this.results.length === 0) {
        this.errorText = 'Not found. Use the slug from mawaqit.net/en/…';
      }
    } catch (_err) {
      this.errorText = 'Could not load times';
      this.results = [];
    } finally {
      this.loading = false;
    }
  }

  private async selectMosque(choice: MosqueChoice): Promise<void> {
    await MosqueStore.save(choice);
    router.back();
  }

  build() {
    Column() {
      Text($r('app.string.choose_mosque'))
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.accent'))
        .margin({ top: 16, bottom: 8 })

      TextInput({ placeholder: 'lille or mosque slug', text: this.query })
        .width('82%')
        .height(36)
        .fontSize(13)
        .backgroundColor($r('app.color.card_background'))
        .fontColor($r('app.color.text_primary'))
        .onChange((value: string) => {
          this.query = value;
        })
        .onSubmit(() => {
          this.search();
        })

      Button($r('app.string.search'))
        .margin({ top: 8, bottom: 8 })
        .onClick(() => {
          this.search();
        })

      if (this.loading) {
        Text($r('app.string.loading'))
          .fontSize(13)
          .fontColor($r('app.color.text_secondary'))
      } else if (this.errorText) {
        Text(this.errorText)
          .fontSize(13)
          .fontColor($r('app.color.accent'))
      }

      Scroll() {
        Column() {
          ForEach(this.results, (item: MosqueChoice) => {
            Text(item.label)
              .width('82%')
              .fontSize(13)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
              .padding(8)
              .margin({ bottom: 6 })
              .backgroundColor($r('app.color.card_background'))
              .borderRadius(16)
              .onClick(() => {
                this.selectMosque(item);
              })
          }, (item: MosqueChoice) => item.code)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
    .alignItems(HorizontalAlign.Center)
    .padding({ bottom: 16 })
  }
}
