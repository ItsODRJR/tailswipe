const jwt = require('jsonwebtoken');
const { pool } = require('./db');

const TOKEN_TTL = '30d';

function issueToken(userId) {
  return jwt.sign({ sub: userId }, process.env.JWT_SECRET, { expiresIn: TOKEN_TTL });
}

// Verifies the Bearer token and attaches the authenticated user's id as `req.userId`.
// Every route except /auth/signup and /auth/signin requires this — matches the iOS
// APIClient, which always attaches an Authorization header once signed in.
async function requireAuth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    return res.status(401).json({ error: 'Missing bearer token' });
  }
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const result = await pool.query('SELECT id FROM users WHERE id = $1', [payload.sub]);
    if (result.rows.length === 0) {
      return res.status(401).json({ error: 'User no longer exists' });
    }
    req.userId = payload.sub;
    next();
  } catch (error) {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}

module.exports = { issueToken, requireAuth };
