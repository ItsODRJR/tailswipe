const express = require('express');
const { pool } = require('../db');
const { requireAuth } = require('../auth');
const { petJSON, preferencesJSON, userJSON, adoptionRequestInfoJSON } = require('../serialize');

const router = express.Router();
router.use(requireAuth);

router.get('/preferences', async (req, res) => {
  const result = await pool.query('SELECT * FROM adoption_preferences WHERE user_id = $1', [req.userId]);
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'No preferences found' });
  }
  res.json(preferencesJSON(result.rows[0]));
});

router.patch('/preferences', async (req, res) => {
  const prefs = req.body;
  const result = await pool.query(
    `INSERT INTO adoption_preferences (user_id, species, breeds, age_categories, sizes, max_distance_miles, temperament_tags, open_to_medical_conditions)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
     ON CONFLICT (user_id) DO UPDATE SET
       species = EXCLUDED.species, breeds = EXCLUDED.breeds, age_categories = EXCLUDED.age_categories,
       sizes = EXCLUDED.sizes, max_distance_miles = EXCLUDED.max_distance_miles,
       temperament_tags = EXCLUDED.temperament_tags, open_to_medical_conditions = EXCLUDED.open_to_medical_conditions
     RETURNING *`,
    [
      req.userId, prefs.species, prefs.breeds ?? null, prefs.ageCategories, prefs.sizes,
      prefs.maxDistanceMiles, prefs.temperamentTags ?? null, prefs.openToMedicalConditions ?? true
    ]
  );
  res.json(preferencesJSON(result.rows[0]));
});

// PATCH /me/profile — the client sends the whole User object it has locally, but only
// display name / bio / avatar / location are ever meant to change here.
router.patch('/profile', async (req, res) => {
  const u = req.body;
  const location = u.location || {};
  const result = await pool.query(
    `UPDATE users SET display_name = $1, bio = $2, avatar_image_path = $3, latitude = $4, longitude = $5, city = $6, region = $7
     WHERE id = $8 RETURNING *`,
    [
      u.displayName, u.bio ?? null, u.avatarImagePath ?? null,
      location.latitude ?? null, location.longitude ?? null, location.city ?? null, location.region ?? null,
      req.userId
    ]
  );
  res.json(userJSON(result.rows[0]));
});

// POST /me/device-token — registers (or clears, if deviceToken is null) the APNs token
// for push notifications. Called on launch once the app has registered for remote
// notifications, and whenever the token rotates.
router.post('/device-token', async (req, res) => {
  const { deviceToken } = req.body;
  await pool.query('UPDATE users SET apns_device_token = $1 WHERE id = $2', [deviceToken ?? null, req.userId]);
  res.json({});
});

router.get('/interests', async (req, res) => {
  const result = await pool.query(
    `SELECT p.* FROM pets p
     JOIN swipe_records s ON s.pet_id = p.id
     WHERE s.user_id = $1 AND s.decision IN ('interested', 'superInterested')
     ORDER BY p.created_at DESC`,
    [req.userId]
  );
  res.json(result.rows.map(petJSON));
});

router.get('/listings', async (req, res) => {
  const result = await pool.query(
    'SELECT * FROM pets WHERE listed_by_id = $1 ORDER BY created_at DESC',
    [req.userId]
  );
  res.json(result.rows.map(petJSON));
});

// GET /me/requests — pending requests on pets the current user listed, super-interest
// bumped to the front of the queue.
router.get('/requests', async (req, res) => {
  // r.* and p.* both have `id`/`created_at` columns — pg would let the pet's values
  // silently clobber the request's in the plain object it builds, so the request's own
  // columns are aliased away from that collision.
  const result = await pool.query(
    `SELECT r.id AS request_id, r.is_super AS request_is_super, r.created_at AS request_created_at,
            p.*,
            u.id AS adopter_id_col, u.email AS adopter_email, u.display_name AS adopter_display_name,
            u.latitude AS adopter_latitude, u.longitude AS adopter_longitude, u.city AS adopter_city, u.region AS adopter_region,
            u.bio AS adopter_bio, u.avatar_image_path AS adopter_avatar_image_path, u.created_at AS adopter_created_at
     FROM adoption_requests r
     JOIN pets p ON p.id = r.pet_id
     JOIN users u ON u.id = r.adopter_id
     WHERE r.lister_id = $1 AND r.status = 'pending'
     ORDER BY r.is_super DESC, r.created_at DESC`,
    [req.userId]
  );

  const infos = result.rows.map((row) => {
    const requestRow = { id: row.request_id, is_super: row.request_is_super, created_at: row.request_created_at };
    const adopterRow = {
      id: row.adopter_id_col,
      email: row.adopter_email,
      display_name: row.adopter_display_name,
      latitude: row.adopter_latitude,
      longitude: row.adopter_longitude,
      city: row.adopter_city,
      region: row.adopter_region,
      bio: row.adopter_bio,
      avatar_image_path: row.adopter_avatar_image_path,
      created_at: row.adopter_created_at
    };
    return adoptionRequestInfoJSON(requestRow, row, adopterRow);
  });

  res.json(infos);
});

module.exports = router;
