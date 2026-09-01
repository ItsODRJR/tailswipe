const express = require('express');
const crypto = require('crypto');
const bcrypt = require('bcryptjs');
const { pool } = require('../db');
const { issueToken } = require('../auth');
const { userJSON } = require('../serialize');
const { authLimiter } = require('../rateLimit');
const { sendVerificationEmail } = require('../mailer');

const router = express.Router();
router.use(authLimiter);

const CODE_TTL_MINUTES = 15;

function generateCode() {
  return String(crypto.randomInt(0, 1_000_000)).padStart(6, '0');
}

async function issueAndSendCode(userId, email) {
  const code = generateCode();
  const expiresAt = new Date(Date.now() + CODE_TTL_MINUTES * 60 * 1000);
  await pool.query(
    'UPDATE users SET verification_code = $1, verification_expires_at = $2 WHERE id = $3',
    [code, expiresAt, userId]
  );
  await sendVerificationEmail(email, code);
}

const DEFAULT_PREFERENCES = {
  species: ['dog', 'cat'],
  breeds: null,
  ageCategories: ['baby', 'young', 'adult', 'senior'],
  sizes: ['small', 'medium', 'large', 'xlarge'],
  maxDistanceMiles: 25,
  temperamentTags: null,
  openToMedicalConditions: true
};

router.post('/signup', async (req, res) => {
  const { email, password, displayName } = req.body;
  if (!email || !password || !displayName) {
    return res.status(400).json({ error: 'email, password, and displayName are required' });
  }
  const normalizedEmail = String(email).toLowerCase();

  const existing = await pool.query('SELECT id FROM users WHERE email = $1', [normalizedEmail]);
  if (existing.rows.length > 0) {
    return res.status(409).json({ error: 'An account with that email already exists.' });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const userResult = await pool.query(
    `INSERT INTO users (email, password_hash, display_name)
     VALUES ($1, $2, $3) RETURNING *`,
    [normalizedEmail, passwordHash, displayName]
  );
  const user = userResult.rows[0];

  await pool.query(
    `INSERT INTO adoption_preferences (user_id, species, breeds, age_categories, sizes, max_distance_miles, temperament_tags, open_to_medical_conditions)
     VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
    [
      user.id,
      DEFAULT_PREFERENCES.species,
      DEFAULT_PREFERENCES.breeds,
      DEFAULT_PREFERENCES.ageCategories,
      DEFAULT_PREFERENCES.sizes,
      DEFAULT_PREFERENCES.maxDistanceMiles,
      DEFAULT_PREFERENCES.temperamentTags,
      DEFAULT_PREFERENCES.openToMedicalConditions
    ]
  );

  await issueAndSendCode(user.id, normalizedEmail);

  // No token yet — the account isn't usable until /auth/verify-email succeeds.
  res.status(201).json({ needsVerification: true, email: normalizedEmail });
});

router.post('/signin', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }
  const normalizedEmail = String(email).toLowerCase();

  const result = await pool.query('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
  const user = result.rows[0];
  if (!user || !(await bcrypt.compare(password, user.password_hash))) {
    return res.status(401).json({ error: 'Incorrect email or password.' });
  }

  if (!user.email_verified) {
    await issueAndSendCode(user.id, normalizedEmail);
    return res.status(403).json({ needsVerification: true, email: normalizedEmail, error: 'Please verify your email to continue.' });
  }

  res.json({ token: issueToken(user.id), user: userJSON(user) });
});

router.post('/verify-email', async (req, res) => {
  const { email, code } = req.body;
  if (!email || !code) {
    return res.status(400).json({ error: 'email and code are required' });
  }
  const normalizedEmail = String(email).toLowerCase();

  const result = await pool.query('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
  const user = result.rows[0];
  if (!user) {
    return res.status(404).json({ error: 'No account found for that email.' });
  }
  if (user.email_verified) {
    return res.json({ token: issueToken(user.id), user: userJSON(user) });
  }
  if (!user.verification_code || user.verification_code !== String(code).trim()
      || !user.verification_expires_at || new Date(user.verification_expires_at) < new Date()) {
    return res.status(400).json({ error: 'That code is invalid or has expired.' });
  }

  const updateResult = await pool.query(
    `UPDATE users SET email_verified = true, verification_code = NULL, verification_expires_at = NULL
     WHERE id = $1 RETURNING *`,
    [user.id]
  );
  const verifiedUser = updateResult.rows[0];

  res.json({ token: issueToken(verifiedUser.id), user: userJSON(verifiedUser) });
});

router.post('/resend-verification', async (req, res) => {
  const { email } = req.body;
  if (!email) {
    return res.status(400).json({ error: 'email is required' });
  }
  const normalizedEmail = String(email).toLowerCase();

  const result = await pool.query('SELECT * FROM users WHERE email = $1', [normalizedEmail]);
  const user = result.rows[0];
  // Same response whether or not the account exists, so this can't be used to enumerate emails.
  if (user && !user.email_verified) {
    await issueAndSendCode(user.id, normalizedEmail);
  }
  res.json({});
});

module.exports = router;
