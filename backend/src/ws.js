const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { URL } = require('url');

// userId -> Set<WebSocket>. A user can have more than one live connection (e.g. app
// backgrounded on one device, foregrounded on another), so sockets are a set, not a slot.
const userSockets = new Map();

function attach(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    const url = new URL(req.url, 'http://localhost');
    const token = url.searchParams.get('token');
    let userId;
    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET);
      userId = payload.sub;
    } catch {
      ws.close(4001, 'Invalid or missing token');
      return;
    }

    if (!userSockets.has(userId)) {
      userSockets.set(userId, new Set());
    }
    userSockets.get(userId).add(ws);

    ws.on('close', () => {
      userSockets.get(userId)?.delete(ws);
    });
  });

  return wss;
}

// Fire-and-forget push to every live socket for a user. Silently a no-op if the user
// (e.g. a shelter lister_id that isn't a real account, or an offline user) has no
// connected sockets — that's expected, not an error.
function broadcastToUser(userId, payload) {
  const sockets = userSockets.get(userId);
  if (!sockets || sockets.size === 0) return;
  const message = JSON.stringify(payload);
  for (const ws of sockets) {
    if (ws.readyState === ws.OPEN) ws.send(message);
  }
}

function isUserOnline(userId) {
  const sockets = userSockets.get(userId);
  return !!sockets && sockets.size > 0;
}

module.exports = { attach, broadcastToUser, isUserOnline };
