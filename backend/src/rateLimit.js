const rateLimit = require('express-rate-limit');

// Generous ceiling for normal API traffic (feed polling, chat, etc).
const generalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 600,
  standardHeaders: true,
  legacyHeaders: false
});

// Tighter limit on auth endpoints specifically, to slow down credential
// stuffing / brute-force signin attempts.
const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many attempts. Please try again later.' }
});

module.exports = { generalLimiter, authLimiter };
