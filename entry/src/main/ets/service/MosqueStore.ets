import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { MosqueChoice } from '../model/Models';

const STORE = 'awqat_watch';
const KEY_CODE = 'mosque_code';
const KEY_LABEL = 'mosque_label';
const KEY_ALIAS = 'mosque_alias';

export class MosqueStore {
  private static prefs: preferences.Preferences | null = null;

  static async init(context: common.UIAbilityContext): Promise<void> {
    MosqueStore.prefs = await preferences.getPreferences(context, STORE);
  }

  static async load(): Promise<MosqueChoice | null> {
    if (!MosqueStore.prefs) {
      return null;
    }
    const code = `${await MosqueStore.prefs.get(KEY_CODE, '')}`;
    if (!code) {
      return null;
    }
    const choice = new MosqueChoice();
    choice.code = code;
    choice.label = `${await MosqueStore.prefs.get(KEY_LABEL, code)}`;
    choice.alias = `${await MosqueStore.prefs.get(KEY_ALIAS, code)}`;
    return choice;
  }

  static async save(choice: MosqueChoice): Promise<void> {
    if (!MosqueStore.prefs) {
      return;
    }
    await MosqueStore.prefs.put(KEY_CODE, choice.code);
    await MosqueStore.prefs.put(KEY_LABEL, choice.label);
    await MosqueStore.prefs.put(KEY_ALIAS, choice.alias);
    await MosqueStore.prefs.flush();
  }
}
