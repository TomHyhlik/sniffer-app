# Flutter Android Development Setup

Installed on 2026-03-28. Log of everything added to this system for Flutter/Android development.

---

## What was already present (not installed in this session)

- **Android Studio** — `/home/tomas/Programs/android-studio/`
- **Android SDK** — `/home/tomas/Android/Sdk/`
  - platform-tools (adb, etc.)
  - platforms/android-36
  - build-tools (35.0.0, 36.0.0, 36.1.0)
  - emulator
- **OpenJDK 21** — `/usr/lib/jvm/java-21-openjdk-amd64`

---

## Installed in this session

### 1. Flutter SDK (via snap) — ~1.1 GB

```bash
sudo snap install flutter --classic
```

- **Location:** `/snap/flutter/current/` (managed by snapd)
- **Version:** 3.41.6 (stable)
- **To remove:**
  ```bash
  sudo snap remove flutter
  ```

### 2. Android cmdline-tools — ~159 MB

Downloaded from Google and extracted manually.

- **Location:** `/home/tomas/Android/Sdk/cmdline-tools/latest/`
- **Source:** `https://dl.google.com/android/repository/commandlinetools-linux-13114758_latest.zip`
- **To remove:**
  ```bash
  rm -rf /home/tomas/Android/Sdk/cmdline-tools/
  ```

### 3. Android SDK licenses (accepted)

Running `sdkmanager --licenses` wrote license acceptance files.

- **Location:** `/home/tomas/Android/Sdk/licenses/`
- **To remove:**
  ```bash
  rm -rf /home/tomas/Android/Sdk/licenses/
  ```

---

## Environment variables added to `~/.bashrc`

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export ANDROID_SDK_ROOT="$HOME/Android/Sdk"
export JAVA_HOME="/usr/lib/jvm/java-21-openjdk-amd64"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/build-tools/36.1.0:$PATH"
```

To undo, remove these lines from `~/.bashrc`.

---

## Flutter config

Flutter was pointed at the Android SDK:

```bash
flutter config --android-sdk "$ANDROID_HOME"
```

Config stored in `~/.config/flutter/` (small, no significant disk usage).

---

## To uninstall everything from this session

```bash
# 1. Remove Flutter snap (~1.1 GB)
sudo snap remove flutter

# 2. Remove Android cmdline-tools (~159 MB)
rm -rf ~/Android/Sdk/cmdline-tools/

# 3. Remove Android SDK licenses (tiny)
rm -rf ~/Android/Sdk/licenses/

# 4. Remove Flutter config (tiny)
rm -rf ~/.config/flutter/

# 5. Remove environment variables from ~/.bashrc
#    (delete the "Flutter & Android development" block)
```

Total disk freed: ~1.3 GB

---

## Verification

```
flutter doctor output (2026-03-28):
[✓] Flutter (Channel stable, 3.41.6)
[✓] Android toolchain (Android SDK version 36.1.0)
[✓] Chrome
[✓] Linux toolchain
[✓] Connected device (2 available)
[✓] Network resources
• No issues found!
```
