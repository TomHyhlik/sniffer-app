# sniffer-app

A Flutter Android app that scans for nearby BLE (Bluetooth Low Energy) devices and displays them grouped by vendor, device type, MAC address, and raw advertisement data.

## Features

- Real-time BLE scanning with configurable scan duration (5 s – 5 min)
- Device count shown live in the title bar
- Scan progress bar with auto-stop
- Tabs: Vendors · Types · Raw · Packets
- Vendor classification and logo display

## Dependencies

### Flutter packages (`sniffer_app/pubspec.yaml`)

| Package | Version | Purpose |
|---|---|---|
| `flutter_blue_plus` | ^1.35.3 | BLE scanning |
| `permission_handler` | ^11.4.0 | Runtime Bluetooth & location permissions |
| `font_awesome_flutter` | ^10.7.0 | Vendor brand icons |
| `cupertino_icons` | ^1.0.8 | iOS-style icons |

### System requirements

| Tool | Minimum version |
|---|---|
| Flutter | 3.x (Dart SDK ^3.11.4) |
| Android SDK | API 21 (Android 5.0) minimum |
| JDK | 17 |

## Environment setup

### 1. Install Flutter

Follow the official guide for your OS: https://docs.flutter.dev/get-started/install

Verify:

```bash
flutter doctor
```

All required components (Flutter, Dart, Android toolchain) must show a green checkmark.

### 2. Install Android SDK

Install **Android Studio**, then open **SDK Manager** and install:

- Android SDK Platform (API 33 or later recommended)
- Android SDK Build-Tools
- Android SDK Command-line Tools

Set `ANDROID_HOME` if not set automatically:

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### 3. Accept Android licenses

```bash
flutter doctor --android-licenses
```

### 4. Clone and install dependencies

```bash
git clone https://github.com/TomHyhlik/sniffer-app.git
cd sniffer-app/sniffer_app
flutter pub get
```

## Building

### Release APK

```bash
cd sniffer_app
flutter build apk
```

Output: `sniffer_app/build/app/outputs/flutter-apk/app-release.apk`

### Debug APK

```bash
cd sniffer_app
flutter build apk --debug
```

### Run directly on a connected device

```bash
cd sniffer_app
flutter run
```

## Permissions

The app requests the following Android permissions at runtime:

| Permission | Reason |
|---|---|
| `BLUETOOTH_SCAN` | Scan for nearby BLE devices |
| `BLUETOOTH_CONNECT` | Required by the Android BLE stack |
| `ACCESS_FINE_LOCATION` | Required by Android for BLE scanning |

## Running tests

```bash
cd sniffer_app
flutter test
```
