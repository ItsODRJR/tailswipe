const express = require('express');
const { pool } = require('../db');
const { requireAuth } = require('../auth');
const { chatThreadJSON, chatMessageJSON } = require('../serialize');
const { broadcastToUser } = require('../ws');
const { notifyNewMessage } = require('../push');

const router = express.Router();
router.use(requireAuth);

router.get('/', async (req, res) => {
  const result = await pool.query(
    `SELECT * FROM chat_threads WHERE participant_user_id = $1
     ORDER BY COALESCE(last_message_at, created_at) DESC`,
    [req.userId]
  );
  res.json(result.rows.map(chatThreadJSON));
});

// POST /threads — fetch-or-create for the given pet, with the caller as the participant.
// listerID isn't sent over the wire; it's derived from the pet's own listedBy.id.
router.post('/', async (req, res) => {
  const { petID } = req.body;

  const petResult = await pool.query('SELECT listed_by_id FROM pets WHERE id = $1', [petID]);
  if (petResult.rows.length === 0) {
    return res.status(404).json({ error: 'That pet could not be found.' });
  }
  const listerId = petResult.rows[0].listed_by_id;

  const result = await pool.query(
    `INSERT INTO chat_threads (pet_id, participant_user_id, lister_id)
     VALUES ($1, $2, $3)
     ON CONFLICT (pet_id, participant_user_id) DO UPDATE SET pet_id = EXCLUDED.pet_id
     RETURNING *`,
    [petID, req.userId, listerId]
  );
  res.status(201).json(chatThreadJSON(result.rows[0]));
});

router.get('/:id/messages', async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM chat_messages WHERE thread_id = $1 ORDER BY sent_at ASC',
    [req.params.id]
  );
  res.json(result.rows.map(chatMessageJSON));
});

router.post('/:id/messages', async (req, res) => {
  const { body } = req.body;
  if (!body || !String(body).trim()) {
    return res.status(400).json({ error: 'Message body cannot be empty' });
  }

  const threadResult = await pool.query(
    'SELECT participant_user_id, lister_id FROM chat_threads WHERE id = $1',
    [req.params.id]
  );
  if (threadResult.rows.length === 0) {
    return res.status(404).json({ error: 'That chat thread could not be found.' });
  }
  const { participant_user_id: participantUserId, lister_id: listerId } = threadResult.rows[0];

  const result = await pool.query(
    `INSERT INTO chat_messages (thread_id, sender_id, body) VALUES ($1, $2, $3) RETURNING *`,
    [req.params.id, req.userId, body]
  );
  const message = result.rows[0];

  await pool.query(
    'UPDATE chat_threads SET last_message_preview = $1, last_message_at = $2 WHERE id = $3',
    [body, message.sent_at, req.params.id]
  );

  const json = chatMessageJSON(message);
  const recipientId = req.userId === participantUserId ? listerId : participantUserId;
  broadcastToUser(recipientId, { type: 'message', message: json });
  notifyNewMessage({ recipientUserId: recipientId, senderId: req.userId, body }).catch((err) => console.error(err));

  res.status(201).json(json);
});

module.exports = router;
