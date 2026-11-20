#!/usr/bin/env bash
set -euo pipefail

ok() { printf '  [ok] %s\n' "$1"; }
warn() { printf '  [!!] %s\n' "$1"; }

echo "Awqat watch — environment check"
echo

arch="$(uname -m)"
os="$(uname -s)"
echo "Host: ${os} ${arch}"

if command -v java >/dev/null 2>&1; then
  java_ver="$(java -version 2>&1 | head -n 1)"
  ok "Java: ${java_ver}"
else
  warn "Java is not on PATH. Install OpenJDK 21 (needed by HarmonyOS sign tools)."
fi

if command -v node >/dev/null 2>&1; then
  ok "Node: $(node -v)"
else
  warn "Node.js is not on PATH. DevEco Studio bundles its own; CLI builds need it."
fi

if command -v hdc >/dev/null 2>&1; then
  ok "hdc: $(command -v hdc)"
else
  warn "hdc is not installed (device bridge). It ships with DevEco Studio / Command Line Tools."
fi

if command -v ohpm >/dev/null 2>&1; then
  ok "ohpm: $(command -v ohpm)"
else
  warn "ohpm is not installed. Open this project in DevEco Studio on Windows or macOS."
fi

if command -v hvigorw >/dev/null 2>&1; then
  ok "hvigorw: $(command -v hvigorw)"
else
  warn "hvigorw is not installed. HAP builds run in DevEco Studio, not on this machine."
fi

echo
if [[ "${arch}" == "aarch64" || "${arch}" == "arm64" ]] && [[ "${os}" == "Linux" ]]; then
  warn "This is Linux ARM64. Official HarmonyOS Command Line Tools are x64-only,"
  warn "and DevEco Studio is Windows/macOS only. Edit ArkTS here, then compile"
  warn "and sideload from a Windows or Mac PC on the same Wi-Fi as the watch."
fi

echo
echo "Mawaqit"
if curl -fsS --max-time 20 \
  'https://mawaqit.net/en/grande-mosquee-de-paris' \
  | grep -q 'confData'; then
  ok "mawaqit.net mosque pages are reachable"
else
  warn "Could not reach mawaqit.net (needed for mosque times)."
fi

echo
echo "Project files"
root="$(cd "$(dirname "$0")/.." && pwd)"
for required in \
  "${root}/AppScope/app.json5" \
  "${root}/entry/src/main/module.json5" \
  "${root}/entry/src/main/ets/pages/Index.ets" \
  "${root}/entry/src/main/ets/service/MawaqitApi.ets"
do
  if [[ -f "${required}" ]]; then
    ok "${required#${root}/}"
  else
    warn "Missing ${required}"
  fi
done
