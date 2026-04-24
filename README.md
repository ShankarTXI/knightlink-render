# KnightLink

KnightLink is a two-mode Android chess app:

- `Offline vs Stockfish` on the same phone, with White or Black side choice
- `Private online 1v1` with one friend and in-game chat

The project is split into:

- `client/` - Flutter Android app
- `server/` - Node.js realtime room server with move validation and chat

## What Is Already Built

- Flutter Android client from scratch
- Home screen with offline and online modes
- Custom chessboard UI with legal move targeting
- Offline engine mode using `stockfish_flutter_plus`
- Offline side selection for White or Black
- Private room creation and room joining
- Realtime chat UI
- Server-side move validation using `chess.js`
- Room persistence to `server/data/rooms.json`
- Chat throttling and room expiry

## Quick Start

### 1. Start the server

From the project root:

```powershell
npm run server:start
```

That starts the room server on `http://localhost:3000`.

### 2. Open the app

From `client/`:

```powershell
flutter run
```

### 3. If you are testing on an Android emulator

Use this server URL inside the app:

```text
http://10.0.2.2:3000
```

### 4. If you are testing on a real Android phone on the same Wi-Fi

Use your computer's LAN IP in the app, for example:

```text
http://192.168.1.20:3000
```

## APK

A debug APK has already been built here:

- `client/build/app/outputs/flutter-apk/app-debug.apk`

## Verification Already Run

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`
- `npm run server:test`

## Security Summary

- No public matchmaking
- Private room codes
- Per-player secret tokens for socket access
- Server-side move validation and turn enforcement
- Chat message length limits
- Chat cooldown / throttling
- Room auto-expiry
- No raw HTML rendering in chat

More detail is in `SECURITY.md`.

## Important Notes

- The online mode still needs the server running somewhere reachable by both phones.
- For internet play outside the same network, you will need to deploy `server/` to a host or VPS.
- Because the offline engine uses Stockfish, distribution should be treated as `GPLv3` compatible.

## Clean Re-Push

If you want to keep the same GitHub repo name and same Render setup name, but clear things out and push this cleaned project again, follow:

- [CLEAN_REPUSH.md](</C:/Users/shank/Documents/New project 2/CLEAN_REPUSH.md>)
