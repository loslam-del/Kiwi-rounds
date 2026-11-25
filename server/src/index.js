const http = require("node:http");
const crypto = require("node:crypto");
const { WebSocketServer, WebSocket } = require("ws");

const PORT = Number(process.env.PORT || 10000);
const MAX_ROOMS = 100;
const MAX_PLAYERS_PER_ROOM = 8;
const MAX_MESSAGE_BYTES = 8 * 1024;
const rooms = new Map();
const clients = new Map();

const server = http.createServer((req, res) => {
  if (req.url === "/health" || req.url === "/") {
    res.writeHead(200, { "content-type": "application/json; charset=utf-8" });
    res.end(JSON.stringify({ ok: true, service: "kiwi-rounds-server" }));
    return;
  }
  res.writeHead(404);
  res.end("Not found");
});

const wss = new WebSocketServer({
  server,
  path: "/ws",
  maxPayload: MAX_MESSAGE_BYTES
});

function send(ws, type, data = {}) {
  if (ws.readyState === WebSocket.OPEN) {
    ws.send(JSON.stringify({ type, ...data }));
  }
}

function cleanText(value, maxLength) {
  return typeof value === "string" ? value.trim().slice(0, maxLength) : "";
}

function roomList() {
  return [...rooms.values()]
    .filter((room) => room.players.size > 0)
    .map((room) => ({
      id: room.id,
      name: room.name,
      players: room.players.size,
      maxPlayers: MAX_PLAYERS_PER_ROOM,
      locked: Boolean(room.passwordHash)
    }))
    .sort((a, b) => a.name.localeCompare(b.name));
}

function broadcastRoomList() {
  const data = roomList();
  for (const ws of wss.clients) send(ws, "room_list", { rooms: data });
}

function broadcastRoomState(room) {
  const state = {
    id: room.id,
    name: room.name,
    hostId: room.hostId,
    players: [...room.players.values()].map((p) => ({
      id: p.id,
      name: p.name,
      isHost: p.id === room.hostId
    }))
  };
  for (const player of room.players.values()) {
    send(player.ws, "room_state", { room: state });
  }
}

function removeFromRoom(ws) {
  const client = clients.get(ws);
  if (!client || !client.roomId) return;
  const room = rooms.get(client.roomId);
  client.roomId = null;
  if (!room) return;

  room.players.delete(client.id);
  if (room.players.size === 0) {
    rooms.delete(room.id);
  } else {
    if (room.hostId === client.id) {
      room.hostId = room.players.keys().next().value;
    }
    broadcastRoomState(room);
  }
  broadcastRoomList();
}

function passwordMatches(password, salt, expectedHex) {
  const actual = crypto.scryptSync(password, salt, 32);
  const expected = Buffer.from(expectedHex, "hex");
  return expected.length === actual.length && crypto.timingSafeEqual(actual, expected);
}

function handleMessage(ws, raw) {
  let message;
  try {
    message = JSON.parse(raw.toString());
  } catch {
    send(ws, "error", { code: "BAD_JSON", message: "Некорректный JSON" });
    return;
  }

  const client = clients.get(ws);
  if (!client || typeof message.type !== "string") return;

  if (message.type === "list_rooms") {
    send(ws, "room_list", { rooms: roomList() });
    return;
  }

  if (message.type === "create_room") {
    const name = cleanText(message.name, 32);
    const password = cleanText(message.password, 64);
    if (name.length < 2) {
      send(ws, "error", { code: "BAD_NAME", message: "Название должно быть от 2 до 32 символов" });
      return;
    }
    if (password.length > 0 && password.length < 4) {
      send(ws, "error", { code: "BAD_PASSWORD", message: "Пароль должен содержать минимум 4 символа" });
      return;
    }
    if (client.roomId) removeFromRoom(ws);
    if (rooms.size >= MAX_ROOMS) {
      send(ws, "error", { code: "ROOM_LIMIT", message: "Сейчас слишком много комнат" });
      return;
    }

    const id = crypto.randomUUID().slice(0, 8);
    const salt = crypto.randomBytes(16).toString("hex");
    const passwordHash = password ? crypto.scryptSync(password, salt, 32).toString("hex") : null;
    const room = {
      id,
      name,
      salt,
      passwordHash,
      hostId: client.id,
      players: new Map()
    };
    rooms.set(id, room);
    room.players.set(client.id, { id: client.id, name: client.name, ws });
    client.roomId = id;
    send(ws, "room_joined", { roomId: id, isHost: true });
    broadcastRoomState(room);
    broadcastRoomList();
    return;
  }

  if (message.type === "join_room") {
    const roomId = cleanText(message.roomId, 16);
    const password = cleanText(message.password, 64);
    const room = rooms.get(roomId);
    if (!room) {
      send(ws, "error", { code: "ROOM_NOT_FOUND", message: "Комната не найдена" });
      return;
    }
    if (room.players.size >= MAX_PLAYERS_PER_ROOM) {
      send(ws, "error", { code: "ROOM_FULL", message: "Комната заполнена" });
      return;
    }
    if (room.passwordHash && !passwordMatches(password, room.salt, room.passwordHash)) {
      send(ws, "error", { code: "WRONG_PASSWORD", message: "Неверный пароль" });
      return;
    }
    if (client.roomId) removeFromRoom(ws);
    room.players.set(client.id, { id: client.id, name: client.name, ws });
    client.roomId = room.id;
    send(ws, "room_joined", { roomId: room.id, isHost: false });
    broadcastRoomState(room);
    broadcastRoomList();
    return;
  }

  if (message.type === "leave_room") {
    removeFromRoom(ws);
    send(ws, "left_room");
    return;
  }

  if (message.type === "set_name") {
    const name = cleanText(message.name, 20);
    if (name.length < 1) {
      send(ws, "error", { code: "BAD_PLAYER_NAME", message: "Введи имя игрока" });
      return;
    }
    client.name = name;
    const room = client.roomId ? rooms.get(client.roomId) : null;
    if (room && room.players.has(client.id)) {
      room.players.get(client.id).name = name;
      broadcastRoomState(room);
    }
    return;
  }

  if (message.type === "start_match") {
    const room = client.roomId ? rooms.get(client.roomId) : null;
    if (!room) {
      send(ws, "error", { code: "NOT_IN_ROOM", message: "Сначала войди в комнату" });
      return;
    }
    if (room.hostId !== client.id) {
      send(ws, "error", { code: "HOST_ONLY", message: "Начать матч может только создатель комнаты" });
      return;
    }
    if (room.players.size !== 2) {
      send(ws, "error", { code: "NEED_TWO_PLAYERS", message: "Для боя нужны ровно два игрока" });
      return;
    }
    const roundsToWin = Math.max(1, Math.min(15, Number(message.roundsToWin) || 5));
    for (const player of room.players.values()) send(player.ws, "match_started", { roomId: room.id, hostId: room.hostId, roundsToWin });
    return;
  }

  if (message.type === "game_input") {
    const room = client.roomId ? rooms.get(client.roomId) : null;
    if (!room || room.players.size !== 2) return;
    if (room.hostId === client.id) return;
    const host = room.players.get(room.hostId);
    if (host) send(host.ws, "game_input", {
      playerId: client.id,
      input: {
        move: Math.max(-1, Math.min(1, Number(message.input?.move) || 0)),
        aimX: Math.max(-1, Math.min(1, Number(message.input?.aimX) || 0)),
        aimY: Math.max(-1, Math.min(1, Number(message.input?.aimY) || 0)),
        jump: Boolean(message.input?.jump),
        fire: Boolean(message.input?.fire),
        reload: Boolean(message.input?.reload)
      }
    });
    return;
  }

  if (message.type === "game_state") {
    const room = client.roomId ? rooms.get(client.roomId) : null;
    if (!room || room.hostId !== client.id || room.players.size !== 2) return;
    const state = message.state;
    if (!state || typeof state !== "object") return;
    const guest = [...room.players.values()].find((p) => p.id !== client.id);
    if (guest) send(guest.ws, "game_state", { state });
    return;
  }

  send(ws, "error", { code: "UNKNOWN_MESSAGE", message: "Неизвестная команда" });
}

wss.on("connection", (ws) => {
  const id = crypto.randomUUID();
  clients.set(ws, { id, name: "Игрок", roomId: null });
  send(ws, "connected", { playerId: id });
  send(ws, "room_list", { rooms: roomList() });

  ws.on("message", (raw) => handleMessage(ws, raw));
  ws.on("close", () => {
    removeFromRoom(ws);
    clients.delete(ws);
  });
  ws.on("error", () => {
    removeFromRoom(ws);
    clients.delete(ws);
  });
});

const heartbeat = setInterval(() => {
  for (const ws of wss.clients) {
    if (ws.isAlive === false) {
      ws.terminate();
      continue;
    }
    ws.isAlive = false;
    ws.ping();
  }
}, 30000);

wss.on("connection", (ws) => {
  ws.isAlive = true;
  ws.on("pong", () => { ws.isAlive = true; });
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`Kiwi Rounds server listening on ${PORT}`);
});

function shutdown() {
  clearInterval(heartbeat);
  for (const ws of wss.clients) ws.close(1001, "Server restarting");
  server.close(() => process.exit(0));
  setTimeout(() => process.exit(0), 5000).unref();
}
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);
