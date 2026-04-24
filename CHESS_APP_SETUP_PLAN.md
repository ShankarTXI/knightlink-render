# Chess App Setup Plan

This project will be built as an Android app with:

- Private `1 vs 1` online chess with one friend
- In-game chat during friend matches
- Offline play against a Stockfish-compatible engine
- APK output for Android phones

## Recommended Stack

- Frontend: `Flutter`
- Backend: `Firebase`
- Database / Realtime sync: `Cloud Firestore`
- Authentication: `Firebase Anonymous Auth` at first
- Offline engine: `Stockfish` via UCI integration

## Why This Stack

- Flutter can produce an Android APK from one codebase.
- Firebase is the fastest way to build secure two-player private rooms and chat.
- Anonymous auth lets each player have an identity without a complicated sign-up flow.
- Firestore security rules can limit access so only the two players in a room can read moves and chat.

## Build Phases

### Phase 1: Local Setup

Install:

- Flutter SDK
- Android Studio
- Android SDK
- JDK 17

Confirm these commands work:

- `flutter --version`
- `flutter doctor`
- `adb --version`
- `java -version`

### Phase 2: App Foundation

Create:

- Flutter project
- Android build config
- App theme
- Navigation
- Chess board screen shell

### Phase 3: Chess Gameplay

Implement:

- Board rendering
- Piece movement
- Legal move validation
- Check / checkmate / stalemate
- Move history
- Game reset / resign / draw flow

### Phase 4: Offline Engine

Implement:

- Bundle Stockfish-compatible binary for Android
- UCI communication layer
- Difficulty levels
- Offline game screen

### Phase 5: Online Friend Play

Implement:

- Private room creation
- Room code join
- Realtime move sync
- Turn ownership
- Game state validation

### Phase 6: Chat

Implement:

- Realtime chat inside each room
- Basic timestamps
- Rate limits and message length limits

### Phase 7: Security Hardening

Add:

- Firestore security rules
- Auth checks for room access
- Validation for legal moves and turn order
- Private unguessable room IDs
- Abuse protections for chat spam
- Safe release signing for APK

### Phase 8: Testing and APK

Test:

- Two devices online play
- Chat delivery
- Offline engine play
- Reconnect behavior
- Invalid move rejection

Build:

- Debug APK
- Signed release APK

## Security Notes

- Only the two players in a room should read or write room data.
- Never trust the phone alone to decide if a move is valid.
- Chat messages should be length-limited and rate-limited.
- Room IDs should be long and hard to guess.
- Old rooms and chat logs should expire after a time.
- Using Stockfish may require GPL compliance for distribution.

## What I Need From You First

1. Install Flutter.
2. Install Android Studio.
3. Install JDK 17.
4. Open Android Studio once and install Android SDK components.
5. Run `flutter doctor`.
6. Send me the output of `flutter doctor`.

## After That

Once the toolchain is ready, I can:

- create the project from scratch
- add the chess app structure
- set up Firebase-ready code
- build and test the Android APK flow
