# Security Notes

This project is intentionally scoped for private games between two people, not public matchmaking.

## Protections Already Implemented

- Private room codes with no lobby listing
- Per-player secret tokens returned by the server and required for socket access
- Maximum of two players per room
- Server-side legal move validation using `chess.js`
- Turn enforcement on the server
- Chat message sanitizing and trimming
- Chat length limit
- Chat rate limit
- Basic HTTP request throttling per IP
- Room expiry to reduce stale data retention
- Room state persistence so reconnects and restarts are less fragile

## Data Stored

The server stores:

- room code
- player display names
- player secret tokens
- FEN position
- move history
- chat history

This is persisted in:

- `server/data/rooms.json`

## Production Hardening Still Recommended

- Serve the backend over `HTTPS` behind a reverse proxy
- Restrict `CORS` to the final app host(s) if you later add web clients
- Add log rotation and monitoring
- Add a stronger abuse/rate-limit layer at the reverse proxy
- Consider encrypting or rotating persistent player tokens
- Add a real signed release keystore for Android release builds
- Avoid committing `server/data/rooms.json` if it contains live games

## Licensing

The offline engine uses Stockfish through `stockfish_flutter_plus`.
That means redistribution should be handled as `GPLv3` compatible unless you change the engine approach.
