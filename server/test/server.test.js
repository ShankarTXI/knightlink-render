const assert = require('node:assert/strict');
const { spawn } = require('node:child_process');
const path = require('node:path');

const { io } = require('socket.io-client');

const serverRoot = path.resolve(__dirname, '..');

function delay(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function waitFor(callback, label, timeoutMs = 10000) {
  const startedAt = Date.now();
  while (Date.now() - startedAt < timeoutMs) {
    const result = await callback();
    if (result) {
      return result;
    }
    await delay(100);
  }
  throw new Error(`Timed out waiting for ${label}.`);
}

async function postJson(url, body) {
  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  const data = await response.json();
  if (!response.ok) {
    throw new Error(data.message || `HTTP ${response.status}`);
  }
  return data;
}

async function main() {
  const port = 3110;
  const baseUrl = `http://127.0.0.1:${port}`;
  const serverProcess = spawn(process.execPath, ['src/index.js'], {
    cwd: serverRoot,
    env: {
      ...process.env,
      PORT: String(port),
    },
    stdio: ['ignore', 'pipe', 'pipe'],
  });

  let serverLogs = '';
  serverProcess.stdout.on('data', (chunk) => {
    serverLogs += chunk.toString();
  });
  serverProcess.stderr.on('data', (chunk) => {
    serverLogs += chunk.toString();
  });

  let aliceSocket;
  let bobSocket;

  try {
    await waitFor(async () => {
      try {
        const response = await fetch(`${baseUrl}/health`);
        return response.ok;
      } catch {
        return false;
      }
    }, 'server health', 15000);

    const alice = await postJson(`${baseUrl}/rooms/create`, {
      displayName: 'Alice',
    });
    assert.equal(alice.color, 'white');

    let aliceState;
    let aliceSocketError;
    aliceSocket = io(baseUrl, {
      transports: ['websocket'],
      reconnection: false,
      auth: {
        roomCode: alice.roomCode,
        playerToken: alice.playerToken,
      },
    });
    aliceSocket.on('room:state', (state) => {
      aliceState = state;
    });
    aliceSocket.on('server:error', (message) => {
      aliceSocketError = message;
    });
    aliceSocket.on('connect_error', (error) => {
      aliceSocketError = error.message;
    });

    await waitFor(() => aliceState, 'host socket state');
    assert.equal(aliceSocketError, undefined, serverLogs);
    assert.equal(aliceState.status, 'waiting');

    let hostChatAck;
    aliceSocket.emit('chat:send', { message: 'Waiting here.' }, (ack) => {
      hostChatAck = ack;
    });

    await waitFor(
      () =>
        hostChatAck?.ok === true &&
        aliceState?.chat?.some((message) => message.message === 'Waiting here.'),
      'host chat before join',
    );

    const bob = await postJson(`${baseUrl}/rooms/join`, {
      displayName: 'Bob',
      roomCode: alice.roomCode,
    });
    assert.equal(bob.color, 'black');

    let bobState;
    let bobSocketError;
    bobSocket = io(baseUrl, {
      transports: ['websocket'],
      reconnection: false,
      auth: {
        roomCode: bob.roomCode,
        playerToken: bob.playerToken,
      },
    });
    bobSocket.on('room:state', (state) => {
      bobState = state;
    });
    bobSocket.on('server:error', (message) => {
      bobSocketError = message;
    });
    bobSocket.on('connect_error', (error) => {
      bobSocketError = error.message;
    });

    await waitFor(
      () =>
        aliceState &&
        bobState &&
        aliceState.status === 'active' &&
        bobState.status === 'active',
      'active game state',
    );
    assert.equal(bobSocketError, undefined, serverLogs);

    aliceSocket.emit('move:make', {
      from: 'e2',
      to: 'e4',
    });

    await waitFor(
      () =>
        aliceState?.moveHistory?.includes('e4') &&
        bobState?.moveHistory?.includes('e4'),
      'move synchronization',
    );

    bobSocket.emit('chat:send', {
      message: 'Good luck!',
    }, (ack) => {
      bobSocketError = ack?.ok === false ? ack.message : bobSocketError;
    });

    await waitFor(
      () =>
        aliceState?.chat?.some((message) => message.message === 'Good luck!') &&
        bobState?.chat?.some((message) => message.message === 'Good luck!'),
      'chat synchronization',
    );

    console.log(
      JSON.stringify(
        {
          roomCode: alice.roomCode,
          moveHistory: aliceState.moveHistory,
          chatCount: aliceState.chat.length,
          result: 'ok',
        },
        null,
        2,
      ),
    );
  } finally {
    aliceSocket?.close();
    bobSocket?.close();
    serverProcess.kill('SIGTERM');
    await delay(500);
  }
}

main()
  .then(() => {
    process.exit(0);
  })
  .catch((error) => {
    // eslint-disable-next-line no-console
    console.error(error);
    process.exit(1);
  });
