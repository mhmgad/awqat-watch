#!/usr/bin/env bash
# Prepare this machine as far as HarmonyOS watch development can go.
# Official HAP compile/sign/deploy still needs DevEco Studio on Windows or macOS.
set -euo pipefail

echo "Setting up local helpers for Awqat watch development"
echo

if ! command -v java >/dev/null 2>&1; then
  if command -v apt-get >/dev/null 2>&1; then
    echo "Installing OpenJDK 21..."
    sudo apt-get update -qq
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openjdk-21-jdk-headless
  else
    echo "Install JDK 21, then re-run this script." >&2
    exit 1
  fi
fi

java_home="$(dirname "$(dirname "$(readlink -f "$(command -v javac || command -v java)")")")"
if [[ -d "${java_home}" ]]; then
  mkdir -p "${HOME}/.local/bin"
  cat > "${HOME}/.local/bin/awqat-watch-env.sh" <<EOF
export JAVA_HOME="${java_home}"
export PATH="\$JAVA_HOME/bin:\$PATH"
EOF
  echo "Wrote ${HOME}/.local/bin/awqat-watch-env.sh"
fi

arch="$(uname -m)"
if [[ "${arch}" == "x86_64" ]] && [[ "$(uname -s)" == "Linux" ]]; then
  echo
  echo "This host is x86_64 Linux. To install Huawei Command Line Tools:"
  echo "  1. Sign in at https://developer.huawei.com/consumer/en/download/"
  echo "  2. Download Command Line Tools for Linux (commandline-tools-linux-x64-*.zip)"
  echo "  3. unzip it to ~/harmonyos and put bin/, tool/node/bin, and hdc on PATH"
else
  echo
  echo "Skipping Huawei CLI install: this CPU (${arch}) cannot run the official x64 tools."
fi

echo
echo "Next: open this folder in DevEco Studio 5.1+ on Windows or macOS."
echo "Then enable Debug via WLAN on the watch and Run 'entry'."
echo
exec "$(dirname "$0")/check-env.sh"
