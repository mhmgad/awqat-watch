# Awqat

Prayer times from a public [MAWAQIT](https://mawaqit.net) mosque page.

**HUAWEI WATCH FIT 3** is a Lite Wearable: rectangular 408×480, Bluetooth only, no Wi‑Fi, no `hdc`. It cannot run the ArkTS watch app in this repo root. Use the Fit 3 pair below.

## FIT 3 + Android phone

```
android/       Kotlin companion: pick a mosque, fetch MAWAQIT, send times
watch-lite/    JS Lite Wearable app: show next prayer + countdown
```

The watch has no internet. The phone loads `https://mawaqit.net/en/<slug>`, then pushes a small JSON payload over **Huawei Wear Engine**. The watch caches it and counts down locally.

### 1. Android companion

On Windows, macOS, or any machine with Android Studio:

1. Open the `android/` folder.
2. Install **HMS Core** and **Huawei Health** on the phone. Pair the FIT 3 in Health.
3. Apply for the [Wear Engine service](https://developer.huawei.com/consumer/en/doc/connectivity-guides/apply-permission-0000001050755133) on your Huawei developer account and put `agconnect-services.json` in `android/app/` if AppGallery Connect asks for it.
4. After you have a release/debug keystore, copy its SHA-256 **without colons** into `watch-lite` (`PEER_FINGERPRINT` and `supportLists`).
5. Build and install the APK. Load a mosque (`lille`, `grande-mosquee-de-paris`, or a full MAWAQIT URL). Times show on the phone even before the watch is linked.

### 2. FIT 3 watch app

On Windows or macOS with **DevEco Studio 5.1+**:

1. **File → Open** `watch-lite/` (not this repo root).
2. SDK **4.0.0(10)**, device type **liteWearable**, screen **408×480**.
3. Replace `watch-lite/entry/src/main/js/MainAbility/common/wearengine.js` with Huawei’s [Wear Engine Lite SDK](https://developer.huawei.com/consumer/en/doc/connectivity-Library/litewearable-sdk-cn-0000001705004353).
4. Manual-sign the HAP (Lite Wearable has no auto-sign). Read the FIT 3 UDID from **DevEco Assistant**, register it in AppGallery Connect, then set the `.p12` / `.cer` / `.p7b` in Signing Configs.
5. Put the watch cert SHA-256 into `android/.../SyncConfig.kt` (`WATCH_FINGERPRINT`).
6. Copy the signed HAP to the phone at `/sdcard/haps/` and install it with **DevEco Assistant** while the FIT 3 is connected in Huawei Health.

Cursor Cloud and this Raspberry Pi cannot compile the HAP or the APK, and they cannot talk to the watch over Bluetooth.

### Wear Engine payload

Under 1 KB:

```json
{"v":1,"n":"Lille","s":"lille","d":"2026-11-20","f":"06:49","h":"12:38","j":"12:45","a":"14:34","m":"16:58","i":"18:17"}
```

## Watch 4 / Watch 5 (Wi‑Fi HarmonyOS)

The repo root is still an ArkTS Stage Model wearable for devices with **Debug via WLAN**. Those watches are not FIT 3. Setup: DevEco Studio on Windows/macOS, same Wi‑Fi as the watch, **Run ‘entry’**.

## Data source

MAWAQIT’s REST API needs an account token. This client reads the public mosque page and the embedded `confData` year calendar (Fajr, Shuruq, Dhuhr, Asr, Maghrib, Isha, plus Jumua).

```bash
./scripts/test_mawaqit.py lille
./scripts/test_mawaqit.py https://mawaqit.net/en/grande-mosquee-de-paris
```
