require('dotenv').config();
const http = require('http');
const express = require('express');
// Patches Express so a rejected promise in any `async` route handler below reaches the
// error middleware via next(err), instead of Express 4 silently swallowing it.
require('express-async-errors');
const ws = require('./ws');

const authRoutes = require('./routes/auth');
const petsRoutes = require('./routes/pets');
const meRoutes = require('./routes/me');
const threadsRoutes = require('./routes/threads');
const uploadsRoutes = require('./routes/uploads');
const { generalLimiter } = require('./rateLimit');

const app = express();
app.use(express.json());
app.use(generalLimiter);

app.get('/health', (req, res) => res.json({ status: 'ok' }));

app.use('/uploads', express.static(require('path').join(__dirname, '..', 'uploads')));
app.use('/uploads', uploadsRoutes);

app.use('/auth', authRoutes);
app.use('/pets', petsRoutes);
app.use('/me', meRoutes);
app.use('/threads', threadsRoutes);

// Centralized error handler so a thrown/rejected error in any route becomes a clean 500
// instead of Express's default HTML error page (which the iOS JSON decoder can't parse).
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const port = process.env.PORT || 4000;
const server = http.createServer(app);
ws.attach(server);
server.listen(port, () => {
  console.log(`Tailswipe API (+ WebSocket at /ws) listening on port ${port}`);
});
