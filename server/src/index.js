const crypto = require('crypto');
const fs = require('fs/promises');
const path = require('path');
const http = require('http');

const cors = require('cors');
const express = require('express');
const helmet = require('helmet');
const { Chess } = require('chess.js');
const { Server } = require('socket.io');
const { z } = require('zod');

const PORT = Number.parseInt(process.env.PORT ?? '3000', 10);
const ROOM_TTL_MS =
  Number.parseInt(process.env.ROOM_TTL_MINUTES ?? '180', 10) * 60 * 1000;
const MAX_CHAT_MESSAGES = 120;
const MAX_CHAT_LENGTH = 280;
const CHAT_COOLDOWN_MS = 1200;
const MOVE_COOLDOWN_MS = 120;
const HTTP_WINDOW_MS = 60 * 1000;
const HTTP_REQUEST_LIMIT = 80;
const ROOM_CODE_LENGTH = 8;
const ROOM_ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
const DATA_DIR = path.join(__dirname, '..', 'data');
const DATA_FILE = path.join(DATA_DIR, 'rooms.json');

const createRoomSchema = z.object({
  displayName: z.string().trim().min(1).max(24),
});

const joinRoomSchema = z.object({
  displayName: z.string().trim().min(1).max(24),
  roomCode: z.string().trim().min(4).max(12),
});

const socketAuthSchema = z.object({
  roomCode: z.string().trim().min(4).max(12),
  playerToken: z.string().trim().min(20).max(128),
});

const moveSchema = z.object({
  from: z.string().trim().regex(/^[a-h][1-8]$/),
  to: z.string().trim().regex(/^[a-h][1-8]$/),
  promotion: z.string().trim().regex(/^[qrbn]$/).optional(),
});

const chatSchema = z.object({
  message: z.string().trim().min(1).max(MAX_CHAT_LENGTH),
});

const rooms = new Map();
const httpBuckets = new Map();
let persistTimer = null;

const app = express();
app.use(
  helmet({
    contentSecurityPolicy: false,
  }),
);
app.use(
  cors({
    origin: true,
  }),
);
app.use(express.json({ limit: '16kb' }));
app.use((request, response, next) => {
  if (!allowHttpRequest(request.ip ?? 'unknown')) {
    response.status(429).json({
      message: 'Too many requests from this address. Try again shortly.',
    });
    return;
  }
  next();
});

app.get('/', (_request, response) => {
  response.json({
    name: 'KnightLink realtime server',
    rooms: rooms.size,
    uptimeSeconds: Math.floor(process.uptime()),
  });
});

app.get('/health', (_request, response) => {
  response.json({
    ok: true,
    rooms: rooms.size,
    timestamp: new Date().toISOString(),
  });
});

app.post('/rooms/create', (request, response) => {
  try {
    const payload = createRoomSchema.parse(request.body ?? {});
    const displayName = normalizeDisplayName(payload.displayName);
    const room = createRoom(displayName);
    schedulePersist();
    response.json(createSessionPayload(room, room.players.white));
  } catch (error) {
    respondWithError(response, error);
  }
});

app.post('/rooms/join', (request, response) => {
  try {
    const payload = joinRoomSchema.parse(request.body ?? {});
    const displayName = normalizeDisplayName(payload.displayName);
    const roomCode = normalizeRoomCode(payload.roomCode);
    const room = getRoom(roomCode);
    if (!room) {
      response.status(404).json({ message: 'Room not found or already expired.' });
      return;
    }
    if (room.players.black) {
      response.status(409).json({ message: 'This room is already full.' });
      return;
    }
    const player = createPlayer(displayName, 'black');
    room.players.black = player;
    room.status = 'active';
    touchRoom(room);
    appendSystemMessage(room, `${displayName} joined the room.`);
    emitRoomState(room);
    schedulePersist();
    response.json(createSessionPayload(room, player));
  } catch (error) {
    respondWithError(response, error);
  }
});

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: true,
  },
});

io.use((socket, next) => {
  try {
    const auth = socketAuthSchema.parse(socket.handshake.auth ?? {});
    const room = getRoom(auth.roomCode);
    if (!room) {
      next(new Error('Room not found or expired.'));
      return;
    }

    const player = findPlayerByToken(room, auth.playerToken);
    if (!player) {
      next(new Error('Player token is invalid for this room.'));
      return;
    }

    socket.data.roomCode = room.code;
    socket.data.playerId = player.id;
    socket.data.playerColor = player.color;
    next();
  } catch (_error) {
    next(new Error('Socket authentication failed.'));
  }
});

io.on('connection', (socket) => {
  const room = getRoom(socket.data.roomCode);
  if (!room) {
    socket.emit('server:error', {
      message: 'Room not found or already expired.',
    });
    socket.disconnect();
    return;
  }

  const player = findPlayerById(room, socket.data.playerId);
  if (!player) {
    socket.emit('server:error', {
      message: 'Your player session is no longer valid.',
    });
    socket.disconnect();
    return;
  }

  player.connected = true;
  touchRoom(room);
  socket.join(room.code);
  emitRoomState(room);

  socket.on('move:make', (rawPayload, acknowledge) => {
    const respond =
      typeof acknowledge === 'function' ? acknowledge : () => {};
    try {
      const activeRoom = getRoom(socket.data.roomCode);
      if (!activeRoom) {
        throw new Error('Room not found or already expired.');
      }
      const actingPlayer = findPlayerById(activeRoom, socket.data.playerId);
      if (!actingPlayer) {
        throw new Error('Player session is invalid.');
      }
      if (Date.now() - actingPlayer.lastMoveAt < MOVE_COOLDOWN_MS) {
        throw new Error('Move rejected. Slow down slightly and try again.');
      }
      if (activeRoom.status !== 'active' || activeRoom.result) {
        throw new Error('This game is not currently active.');
      }
      if (activeRoom.game.turn() !== colorToTurn(actingPlayer.color)) {
        throw new Error('It is not your turn.');
      }

      const payload = moveSchema.parse(rawPayload ?? {});
      const move = activeRoom.game.move({
        from: payload.from,
        to: payload.to,
        promotion: payload.promotion,
      });
      if (!move) {
        throw new Error('Illegal move.');
      }

      actingPlayer.lastMoveAt = Date.now();
      activeRoom.lastMove = {
        from: move.from,
        to: move.to,
        san: move.san,
      };
      activeRoom.moveHistory.push(move.san);
      activeRoom.result = buildResultLabel(activeRoom.game);
      activeRoom.status = activeRoom.result ? 'finished' : 'active';
      touchRoom(activeRoom);
      emitRoomState(activeRoom);
      schedulePersist();
      respond({ ok: true });
    } catch (error) {
      respond({
        ok: false,
        message: error instanceof Error ? error.message : 'Move rejected.',
      });
      socket.emit('server:error', {
        message: error instanceof Error ? error.message : 'Move rejected.',
      });
    }
  });

  socket.on('chat:send', (rawPayload, acknowledge) => {
    const respond =
      typeof acknowledge === 'function' ? acknowledge : () => {};
    try {
      const activeRoom = getRoom(socket.data.roomCode);
      if (!activeRoom) {
        throw new Error('Room not found or already expired.');
      }
      const actingPlayer = findPlayerById(activeRoom, socket.data.playerId);
      if (!actingPlayer) {
        throw new Error('Player session is invalid.');
      }
      const payload = chatSchema.parse(rawPayload ?? {});
      const message = normalizeChatMessage(payload.message);
      if (!message) {
        throw new Error('Please enter a message.');
      }
      if (Date.now() - actingPlayer.lastChatAt < CHAT_COOLDOWN_MS) {
        throw new Error('You are sending messages too quickly.');
      }

      actingPlayer.lastChatAt = Date.now();
      activeRoom.chat.push({
        id: crypto.randomUUID(),
        senderId: actingPlayer.id,
        senderName: actingPlayer.name,
        message,
        createdAt: new Date().toISOString(),
        system: false,
      });
      if (activeRoom.chat.length > MAX_CHAT_MESSAGES) {
        activeRoom.chat.splice(0, activeRoom.chat.length - MAX_CHAT_MESSAGES);
      }
      touchRoom(activeRoom);
      emitRoomState(activeRoom);
      schedulePersist();
      respond({ ok: true });
    } catch (error) {
      respond({
        ok: false,
        message: error instanceof Error ? error.message : 'Message rejected.',
      });
      socket.emit('server:error', {
        message: error instanceof Error ? error.message : 'Message rejected.',
      });
    }
  });

  socket.on('disconnect', () => {
    const activeRoom = getRoom(socket.data.roomCode);
    if (!activeRoom) {
      return;
    }
    const disconnectedPlayer = findPlayerById(activeRoom, socket.data.playerId);
    if (!disconnectedPlayer) {
      return;
    }
    disconnectedPlayer.connected = isPlayerStillConnected(
      activeRoom.code,
      disconnectedPlayer.id,
    );
    touchRoom(activeRoom);
    emitRoomState(activeRoom);
    schedulePersist();
  });
});

loadPersistedRooms()
  .then(() => {
    pruneExpiredRooms();
    setInterval(pruneExpiredRooms, 60 * 1000).unref();
    server.listen(PORT, () => {
      // eslint-disable-next-line no-console
      console.log(`KnightLink server listening on http://localhost:${PORT}`);
    });
  })
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error('Failed to load persisted rooms:', error);
    process.exitCode = 1;
  });

function allowHttpRequest(ipAddress) {
  const now = Date.now();
  const bucket = httpBuckets.get(ipAddress) ?? {
    count: 0,
    windowStart: now,
  };

  if (now - bucket.windowStart > HTTP_WINDOW_MS) {
    bucket.windowStart = now;
    bucket.count = 0;
  }

  bucket.count += 1;
  httpBuckets.set(ipAddress, bucket);
  return bucket.count <= HTTP_REQUEST_LIMIT;
}

function createRoom(displayName) {
  const code = generateRoomCode();
  const player = createPlayer(displayName, 'white');
  const game = new Chess();
  const room = {
    code,
    createdAt: new Date().toISOString(),
    expiresAt: Date.now() + ROOM_TTL_MS,
    lastActivityAt: new Date().toISOString(),
    status: 'waiting',
    result: null,
    players: {
      white: player,
      black: null,
    },
    moveHistory: [],
    lastMove: null,
    chat: [],
    game,
  };

  appendSystemMessage(room, `${displayName} created the room.`);
  rooms.set(code, room);
  return room;
}

function createPlayer(name, color) {
  return {
    id: crypto.randomUUID(),
    token: crypto.randomBytes(24).toString('hex'),
    name,
    color,
    connected: false,
    lastChatAt: 0,
    lastMoveAt: 0,
  };
}

function createSessionPayload(room, player) {
  return {
    roomCode: room.code,
    playerId: player.id,
    playerToken: player.token,
    playerName: player.name,
    color: player.color,
  };
}

function buildResultLabel(game) {
  if (game.isCheckmate()) {
    const winner = game.turn() === 'w' ? 'Black' : 'White';
    return `${winner} wins by checkmate.`;
  }
  if (game.isStalemate()) {
    return 'Draw by stalemate.';
  }
  if (game.isThreefoldRepetition()) {
    return 'Draw by repetition.';
  }
  if (game.isInsufficientMaterial()) {
    return 'Draw by insufficient material.';
  }
  if (game.isDraw()) {
    return 'Draw.';
  }
  return null;
}

function appendSystemMessage(room, message) {
  room.chat.push({
    id: crypto.randomUUID(),
    senderId: 'system',
    senderName: 'System',
    message,
    createdAt: new Date().toISOString(),
    system: true,
  });
  if (room.chat.length > MAX_CHAT_MESSAGES) {
    room.chat.splice(0, room.chat.length - MAX_CHAT_MESSAGES);
  }
}

function emitRoomState(room) {
  io.to(room.code).emit('room:state', serializeRoom(room));
}

function serializeRoom(room) {
  return {
    roomCode: room.code,
    status: room.result ? 'finished' : room.status,
    fen: room.game.fen(),
    turn: room.game.turn(),
    result: room.result,
    players: {
      white: publicPlayer(room.players.white),
      black: publicPlayer(room.players.black),
    },
    moveHistory: room.moveHistory,
    lastMove: room.lastMove,
    chat: room.chat,
  };
}

function publicPlayer(player) {
  if (!player) {
    return null;
  }
  return {
    id: player.id,
    name: player.name,
    color: player.color,
    connected: player.connected,
  };
}

function normalizeDisplayName(rawValue) {
  const cleaned = rawValue
    .replace(/[^\p{L}\p{N} _.-]/gu, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 24);

  if (!cleaned) {
    throw new Error('Display name is required.');
  }
  return cleaned;
}

function normalizeRoomCode(rawValue) {
  return rawValue.replace(/[^A-Za-z0-9]/g, '').toUpperCase();
}

function normalizeChatMessage(rawValue) {
  return rawValue
    .replace(/[\u0000-\u001F\u007F]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, MAX_CHAT_LENGTH);
}

function generateRoomCode() {
  let code = '';
  do {
    code = Array.from({ length: ROOM_CODE_LENGTH }, () => {
      const index = crypto.randomInt(0, ROOM_ALPHABET.length);
      return ROOM_ALPHABET[index];
    }).join('');
  } while (rooms.has(code));
  return code;
}

function colorToTurn(color) {
  return color === 'white' ? 'w' : 'b';
}

function getRoom(roomCode) {
  const room = rooms.get(normalizeRoomCode(roomCode));
  if (!room) {
    return null;
  }
  if (Date.now() > room.expiresAt) {
    rooms.delete(room.code);
    schedulePersist();
    return null;
  }
  return room;
}

function findPlayerByToken(room, token) {
  return [room.players.white, room.players.black].find(
    (player) => player && player.token === token,
  );
}

function findPlayerById(room, playerId) {
  return [room.players.white, room.players.black].find(
    (player) => player && player.id === playerId,
  );
}

function isPlayerStillConnected(roomCode, playerId) {
  for (const socket of io.sockets.sockets.values()) {
    if (
      socket.connected &&
      socket.data.roomCode === roomCode &&
      socket.data.playerId === playerId
    ) {
      return true;
    }
  }
  return false;
}

function touchRoom(room) {
  room.lastActivityAt = new Date().toISOString();
  room.expiresAt = Date.now() + ROOM_TTL_MS;
}

function pruneExpiredRooms() {
  let removedAny = false;
  for (const room of rooms.values()) {
    if (Date.now() > room.expiresAt) {
      rooms.delete(room.code);
      removedAny = true;
    }
  }
  if (removedAny) {
    schedulePersist();
  }
}

function schedulePersist() {
  if (persistTimer) {
    return;
  }
  persistTimer = setTimeout(async () => {
    persistTimer = null;
    await persistRooms();
  }, 250);
}

async function persistRooms() {
  await fs.mkdir(DATA_DIR, { recursive: true });
  const serializable = {
    rooms: Array.from(rooms.values()).map((room) => ({
      code: room.code,
      createdAt: room.createdAt,
      expiresAt: room.expiresAt,
      lastActivityAt: room.lastActivityAt,
      status: room.status,
      result: room.result,
      players: room.players,
      moveHistory: room.moveHistory,
      lastMove: room.lastMove,
      chat: room.chat,
      fen: room.game.fen(),
    })),
  };
  await fs.writeFile(DATA_FILE, JSON.stringify(serializable, null, 2));
}

async function loadPersistedRooms() {
  try {
    const raw = await fs.readFile(DATA_FILE, 'utf8');
    const parsed = JSON.parse(raw);
    const persistedRooms = Array.isArray(parsed.rooms) ? parsed.rooms : [];

    for (const savedRoom of persistedRooms) {
      if (!savedRoom.code || Date.now() > savedRoom.expiresAt) {
        continue;
      }
      const game = new Chess(savedRoom.fen);
      const room = {
        code: savedRoom.code,
        createdAt: savedRoom.createdAt ?? new Date().toISOString(),
        expiresAt: savedRoom.expiresAt,
        lastActivityAt: savedRoom.lastActivityAt ?? new Date().toISOString(),
        status: savedRoom.result ? 'finished' : savedRoom.status ?? 'waiting',
        result: savedRoom.result ?? null,
        players: {
          white: hydratePlayer(savedRoom.players?.white),
          black: hydratePlayer(savedRoom.players?.black),
        },
        moveHistory: Array.isArray(savedRoom.moveHistory)
            ? savedRoom.moveHistory
            : [],
        lastMove: savedRoom.lastMove ?? null,
        chat: Array.isArray(savedRoom.chat) ? savedRoom.chat : [],
        game,
      };
      rooms.set(room.code, room);
    }
  } catch (error) {
    if (error && error.code === 'ENOENT') {
      return;
    }
    throw error;
  }
}

function hydratePlayer(player) {
  if (!player) {
    return null;
  }
  return {
    id: player.id,
    token: player.token,
    name: player.name,
    color: player.color,
    connected: false,
    lastChatAt: 0,
    lastMoveAt: 0,
  };
}

function respondWithError(response, error) {
  if (error instanceof z.ZodError) {
    response.status(400).json({
      message: error.issues[0]?.message ?? 'Invalid request.',
    });
    return;
  }
  response.status(400).json({
    message: error instanceof Error ? error.message : 'Request failed.',
  });
}
