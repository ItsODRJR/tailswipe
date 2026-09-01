const express = require('express');
const { pool } = require('../db');
const { requireAuth } = require('../auth');
const { petJSON, chatThreadJSON } = require('../serialize');
const { distanceMiles } = require('../distance');
const { notifyRequestAccepted, notifyNewRequest } = require('../push');

const router = express.Router();
router.use(requireAuth);

function splitParam(value) {
  if (!value) return [];
  return String(value).split(',').filter(Boolean);
}

// GET /pets — the swipe deck feed: available pets, not already swiped, not self-listed,
// filtered by species/age/size (and breed if given), sorted by distance if lat/lng are
// provided, otherwise by recency. Mirrors MockPetRepository.fetchFeed exactly.
router.get('/', async (req, res) => {
  const species = splitParam(req.query.species);
  const ageCategories = splitParam(req.query.ageCategories);
  const sizes = splitParam(req.query.sizes);
  const breeds = splitParam(req.query.breeds);
  const maxDistanceMiles = req.query.maxDistanceMiles ? Number(req.query.maxDistanceMiles) : null;
  const lat = req.query.lat ? Number(req.query.lat) : null;
  const lng = req.query.lng ? Number(req.query.lng) : null;

  const result = await pool.query(
    `SELECT p.* FROM pets p
     WHERE p.status = 'available'
       AND p.listed_by_id != $1
       AND p.species = ANY($2)
       AND p.age_category = ANY($3)
       AND p.size = ANY($4)
       AND p.id NOT IN (SELECT pet_id FROM swipe_records WHERE user_id = $1)`,
    [req.userId, species, ageCategories, sizes]
  );

  let candidates = result.rows;

  if (breeds.length > 0) {
    candidates = candidates.filter((row) => row.breed.some((b) => breeds.includes(b)));
  }

  if (lat !== null && lng !== null) {
    candidates = candidates.map((row) => ({
      ...row,
      distance_miles: distanceMiles(lat, lng, row.latitude, row.longitude)
    }));
    if (maxDistanceMiles !== null) {
      candidates = candidates.filter((row) => row.distance_miles <= maxDistanceMiles);
    }
    candidates.sort((a, b) => a.distance_miles - b.distance_miles);
  } else {
    candidates.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));
  }

  res.json(candidates.map(petJSON));
});

router.get('/:id', async (req, res) => {
  const result = await pool.query('SELECT * FROM pets WHERE id = $1', [req.params.id]);
  if (result.rows.length === 0) {
    return res.status(404).json({ error: 'That pet could not be found.' });
  }
  res.json(petJSON(result.rows[0]));
});

// POST /pets — list a new pet. The client generates and sends its own id.
router.post('/', async (req, res) => {
  const p = req.body;
  const result = await pool.query(
    `INSERT INTO pets (
       id, name, species, breed, age_category, age_months, size, sex, temperament_tags,
       medical_conditions, is_vaccinated, is_spayed_neutered, is_good_with_kids, is_good_with_other_pets,
       description, photo_urls, latitude, longitude, city, region,
       source_type, source_label, source_is_verified,
       listed_by_id, listed_by_display_name, listed_by_contact_type, status
     ) VALUES (
       $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27
     ) RETURNING *`,
    [
      p.id, p.name, p.species, p.breed, p.ageCategory, p.ageMonths ?? null, p.size, p.sex, p.temperamentTags ?? [],
      p.medicalConditions ?? null, !!p.isVaccinated, !!p.isSpayedNeutered, !!p.isGoodWithKids, !!p.isGoodWithOtherPets,
      p.description ?? '', p.photoURLs ?? [], p.location.latitude, p.location.longitude, p.location.city ?? null, p.location.region ?? null,
      p.source.type, p.source.label ?? null, !!p.source.isVerified,
      p.listedBy.id, p.listedBy.displayName, p.listedBy.contactType, p.status ?? 'available'
    ]
  );
  res.status(201).json(petJSON(result.rows[0]));
});

// POST /pets/:id/swipe — records the decision and, for interested/superInterested, opens
// a pending adoption request the pet's lister will see on their Requests tab.
router.post('/:id/swipe', async (req, res) => {
  const petId = req.params.id;
  const { decision } = req.body;
  if (!['interested', 'superInterested', 'passed'].includes(decision)) {
    return res.status(400).json({ error: 'Invalid decision' });
  }

  await pool.query(
    `INSERT INTO swipe_records (user_id, pet_id, decision, decided_at)
     VALUES ($1, $2, $3, now())
     ON CONFLICT (user_id, pet_id) DO UPDATE SET decision = EXCLUDED.decision, decided_at = now()`,
    [req.userId, petId, decision]
  );

  if (decision === 'interested' || decision === 'superInterested') {
    const petResult = await pool.query('SELECT name, listed_by_id FROM pets WHERE id = $1', [petId]);
    if (petResult.rows.length > 0) {
      const requestId = `${petId}-${req.userId}`;
      const isSuper = decision === 'superInterested';
      await pool.query(
        `INSERT INTO adoption_requests (id, pet_id, adopter_id, lister_id, status, is_super)
         VALUES ($1, $2, $3, $4, 'pending', $5)
         ON CONFLICT (id) DO NOTHING`,
        [requestId, petId, req.userId, petResult.rows[0].listed_by_id, isSuper]
      );
      notifyNewRequest({
        recipientUserId: petResult.rows[0].listed_by_id,
        petName: petResult.rows[0].name,
        isSuper
      }).catch((err) => console.error(err));
    }
  }

  res.json({});
});

// PATCH /pets/:id — currently only used to change status (e.g. mark adopted).
router.patch('/:id', async (req, res) => {
  const { status } = req.body;
  if (!['available', 'pending', 'adopted'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status' });
  }
  await pool.query('UPDATE pets SET status = $1 WHERE id = $2', [status, req.params.id]);
  res.json({});
});

// GET /pets/:petID/requests/:adopterID — the adopter's own view of their request status
// for a given pet (pending/accepted/declined/none).
router.get('/:petID/requests/:adopterID', async (req, res) => {
  const requestId = `${req.params.petID}-${req.params.adopterID}`;
  const result = await pool.query('SELECT status FROM adoption_requests WHERE id = $1', [requestId]);
  res.json({ status: result.rows.length > 0 ? result.rows[0].status : null });
});

// POST /pets/:petID/requests/respond — the lister accepting or declining an adopter's
// request. Accepting flips the request and opens (or reuses) the chat thread.
router.post('/:petID/requests/respond', async (req, res) => {
  const { petID } = req.params;
  const { adopterID, accept } = req.body;
  const requestId = `${petID}-${adopterID}`;

  const existing = await pool.query('SELECT * FROM adoption_requests WHERE id = $1', [requestId]);
  if (existing.rows.length === 0) {
    return res.json({ thread: null });
  }

  await pool.query(
    "UPDATE adoption_requests SET status = $1 WHERE id = $2",
    [accept ? 'accepted' : 'declined', requestId]
  );

  if (!accept) {
    return res.json({ thread: null });
  }

  const listerId = existing.rows[0].lister_id;
  const threadResult = await pool.query(
    `INSERT INTO chat_threads (pet_id, participant_user_id, lister_id)
     VALUES ($1, $2, $3)
     ON CONFLICT (pet_id, participant_user_id) DO UPDATE SET pet_id = EXCLUDED.pet_id
     RETURNING *`,
    [petID, adopterID, listerId]
  );

  const petResult = await pool.query('SELECT name FROM pets WHERE id = $1', [petID]);
  notifyRequestAccepted({
    recipientUserId: adopterID,
    petName: petResult.rows[0]?.name || 'the pet'
  }).catch((err) => console.error(err));

  res.json({ thread: chatThreadJSON(threadResult.rows[0]) });
});

module.exports = router;
