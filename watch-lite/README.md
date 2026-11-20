# Awqat — HUAWEI WATCH FIT 3

Lite Wearable JS app for the rectangular FIT 3 (408×480, Bluetooth only). The watch has no Wi‑Fi and cannot fetch MAWAQIT itself. Pair it with the Android app in `../android`.

## Open in DevEco Studio

1. Install DevEco Studio 5.1+ on Windows or macOS.
2. **File → Open** this `watch-lite` folder (not the repo root).
3. Template equivalent: **[Lite] Empty Ability**, device type **Lite Wearable**, SDK **4.0.0(10)**.
4. Replace `entry/src/main/js/MainAbility/common/wearengine.js` with Huawei’s [Wear Engine Lite SDK](https://developer.huawei.com/consumer/en/doc/connectivity-Library/litewearable-sdk-cn-0000001705004353) `wearengine.js`.
5. Put the Android app SHA-256 (no colons) in:
   - `entry/src/main/js/MainAbility/common/constants.js` (`PEER_FINGERPRINT`)
   - `entry/src/main/config.json` (`supportLists` value `com.mhmgad.awqat.android:THAT_FINGERPRINT`)
6. Manual-sign the HAP (Lite Wearable does not support DevEco auto-sign). Register the FIT 3 UDID from **DevEco Assistant** in AppGallery Connect, then download the `.cer` / `.p7b` and set **Signing Configs**.

## Install on the FIT 3

The watch has no `hdc` and no Wi‑Fi debug.

1. Build **Build → Build Hap(s)/APP(s) → Build Hap(s)**.
2. Copy `entry/build/default/outputs/default/entry-default-signed.hap` to the phone as `/sdcard/haps/`.
3. FIT 3 paired in **Huawei Health** over Bluetooth.
4. Open **DevEco Assistant** on the phone → install the HAP on the watch.

Huawei Health + DevEco Assistant work on a non-Huawei Android phone. Wear Engine still needs **HMS Core**.
