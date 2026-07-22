#!/usr/bin/env bash
# TinyCanvas Adventures - Codespaces setup (lightweight, reliable)
# Installs Flutter (stable) + Android SDK command line tools, then runs pub get.
# Takes ~4-6 minutes on first create. Safe to re-run.
set -e

echo '=== [1/5] Installing Flutter (stable) ==='
if [ ! -d "$HOME/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$HOME/flutter"
fi
export PATH="$HOME/flutter/bin:$PATH"
if ! grep -q 'flutter/bin' "$HOME/.bashrc"; then
  echo 'export PATH="$HOME/flutter/bin:$PATH"' >> "$HOME/.bashrc"
fi

echo '=== [2/5] Installing Android SDK command line tools ==='
export ANDROID_HOME="$HOME/android-sdk"
if ! grep -q 'ANDROID_HOME' "$HOME/.bashrc"; then
  echo 'export ANDROID_HOME="$HOME/android-sdk"' >> "$HOME/.bashrc"
  echo 'export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"' >> "$HOME/.bashrc"
fi
if [ ! -d "$ANDROID_HOME/cmdline-tools/latest" ]; then
  mkdir -p "$ANDROID_HOME/cmdline-tools"
  cd /tmp
  curl -sSLo cmdtools.zip https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip
  unzip -q cmdtools.zip -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest"
  rm cmdtools.zip
  cd - >/dev/null
fi
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"

echo '=== [3/5] Installing Android platform + build tools ==='
yes | sdkmanager --licenses >/dev/null 2>&1 || true
sdkmanager --install 'platform-tools' 'platforms;android-34' 'build-tools;34.0.0' >/dev/null

echo '=== [4/5] Configuring Flutter ==='
flutter config --no-analytics --android-sdk "$ANDROID_HOME" >/dev/null
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
flutter precache --android >/dev/null

echo '=== [5/5] flutter pub get ==='
flutter pub get

echo ''
echo '============================================'
echo ' Setup complete! Open a NEW terminal, then:'
echo '   flutter --version'
echo '   flutter analyze'
echo '   flutter test'
echo '   flutter build apk --debug'
echo '============================================'
