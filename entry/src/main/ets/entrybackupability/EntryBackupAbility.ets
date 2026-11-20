import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    hilog.info(0x0000, 'EntryBackupAbility', 'onBackup ok');
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    hilog.info(0x0000, 'EntryBackupAbility', 'onRestore ok %{public}s', JSON.stringify(bundleVersion));
  }
}
