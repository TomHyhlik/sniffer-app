# sniffer-app

## Sending the APK

When the user says "send", send the built APK to Telegram using the sender-tool:

```bash
/home/fuzz/Repos/sender-tool/telegram/send-file.sh \
  --file /home/fuzz/Repos/sniffer-app/sniffer_app/build/app/outputs/flutter-apk/app-release.apk \
  --caption "sniffer_app release APK"
```

Config is at `/home/fuzz/Repos/sender-tool/telegram/config.json` (bot token + chat ID already configured).

## Building

```bash
cd /home/fuzz/Repos/sniffer-app/sniffer_app
flutter build apk
```

APK output: `sniffer_app/build/app/outputs/flutter-apk/app-release.apk`
