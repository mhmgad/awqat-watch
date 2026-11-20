# Awqat for HarmonyOS watches

A small wearable app that shows today’s mosque prayer times from [awqat.fr](https://awqat.fr/). Search for a mosque, then the watch lists Fajr, Dhuhr (Jumua on Friday), Asr, Maghrib, and Isha with a countdown to the next one.

Times follow that mosque’s Awqat configuration: published calendar when the mosque uses one, otherwise PrayTimes with the mosque’s method (UOIF, ISNA, …).

## What runs where

HarmonyOS watch apps are built with **DevEco Studio** (ArkTS / ArkUI). Huawei ships that IDE for **Windows and macOS** only. The Linux Command Line Tools package is **x64 only**.

This repository was started on a Raspberry Pi (Linux ARM64). On that machine you can edit the ArkTS sources and check the Awqat API, but you **cannot compile a HAP or install it on the watch**. Do that from a Windows or Mac PC on the same Wi-Fi as the watch.

| Step | Where |
| --- | --- |
| Edit ArkTS, resources, `module.json5` | Any machine (including this Pi) |
| Compile / sign / install on the watch | Windows or macOS + DevEco Studio 5.1 or newer |
| Debug | Watch: **Debug via WLAN** (wearables have no USB debug) |

Target devices: Huawei watches that run **HarmonyOS 5+** (for example Watch 5). Set `deviceTypes` to `wearable` in `entry/src/main/module.json5`.

## One-time setup on Windows or macOS

1. Create a [Huawei Developer](https://developer.huawei.com/) account.
2. Install [DevEco Studio](https://developer.huawei.com/consumer/en/download/deveco-studio) **6.1.0** or newer (SDK is bundled).
3. Open this folder with **File → Open**. If DevEco offers to upgrade `compatibleSdkVersion`, accept it.
4. Wait for the project sync (`ohpm` / hvigor). First run downloads the HarmonyOS SDK plugins.
5. On the watch: Settings → about → tap the version seven times → enable **Developer options** → **Debug via WLAN**. Note the `IP:port`.
6. In DevEco Studio: **Tools → IP Connection**, enter that address, trust the computer on the watch.
7. Click **Run ‘entry’**. DevEco signs a debug HAP and installs it.

Wearables stay connected only while the screen is on; lengthen auto-sleep while you debug.

Official references:

- [Install DevEco Studio](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-software-install)
- [Wireless debugging](https://developer.huawei.com/consumer/en/doc/harmonyos-guides/ide-run-device)
- Wearable template: create an Application with device type **Wearable**, or keep `deviceTypes: ["wearable"]` as in this repo.

## Local helpers (Linux / this Pi)

```bash
./scripts/setup-dev.sh
./scripts/check-env.sh
```

`setup-dev.sh` installs OpenJDK 21 when missing and records `JAVA_HOME`. `check-env.sh` reports which HarmonyOS tools are present and pings the Awqat widget API.

## Project layout

```
AppScope/                      bundle name com.awqat.watch
entry/src/main/ets/pages/      Index (times) and SearchPage (mosque picker)
entry/src/main/ets/service/    Awqat HTTP client, PrayTimes, preferences
entry/src/main/module.json5    wearable device type + INTERNET permission
```

Choose a mosque once; it is stored in device preferences.

## API

Same widget API as the Home Assistant integration:

- `GET https://widget.fawzone.net/widget/findWidgets`
- `POST https://widget.fawzone.net/widget/findCfg`
- `GET https://widget.fawzone.net/awqatCal/byCode/{code}/…`
