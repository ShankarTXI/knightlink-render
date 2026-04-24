# KnightLink Client

Flutter Android client for KnightLink.

## Modes

- Offline play against Stockfish
- Private online play against one friend
- In-game chat for online rooms

## Useful Commands

```powershell
flutter analyze
flutter test
flutter run
flutter build apk --debug
```

## Server URL

The friend mode asks for a server URL in the app.

- Android emulator: `http://10.0.2.2:3000`
- Real phone on same Wi-Fi: `http://<your-computer-lan-ip>:3000`

## Output APK

After a debug build, the APK is written to:

- `build/app/outputs/flutter-apk/app-debug.apk`
