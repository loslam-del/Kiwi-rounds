# Kiwi Rounds — room server

This is the first backend milestone: public room discovery, room creation, password-protected joining, player lists, host handoff, and WebSocket keepalive.

## Deploy on Render

Create a **Web Service** from this GitHub repository and set:

- Root Directory: `server`
- Runtime: Node
- Build Command: `npm install`
- Start Command: `npm start`
- Instance type: Free

The service exposes:
- Health check: `https://YOUR-SERVICE.onrender.com/health`
- WebSocket: `wss://YOUR-SERVICE.onrender.com/ws`

## WebSocket message protocol

Send JSON messages:
- `{"type":"list_rooms"}`
- `{"type":"set_name","name":"Kiwi"}`
- `{"type":"create_room","name":"Room name","password":"optional"}`
- `{"type":"join_room","roomId":"ROOM_ID","password":"optional"}`
- `{"type":"leave_room"}`

Server events:
- `connected`
- `room_list`
- `room_joined`
- `room_state`
- `left_room`
- `error`

## Current limitations

- Room data is held in memory. Rooms disappear when the service restarts or sleeps.
- This backend does not yet relay gameplay inputs, synchronize physics, or reconnect players after a disconnect.
- The Godot client is not connected to this protocol yet; the game UI/client integration is a separate step.
- Render Free services can sleep after 15 minutes without incoming HTTP/WebSocket traffic. The first connection after sleep may take about a minute.
