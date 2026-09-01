// Mirrors ios/Tailswipe/Sources/Tailswipe/Data/MockData/MockSeedData.swift exactly, so
// switching the app from mock to live doesn't lose the curated demo experience — same
// demo login, same pets/photos/locations, same pending requests waiting on the Requests tab.
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('./db');

const DEMO_USER_ID = '00000000-0000-0000-0000-000000000001';
const SHELTER_LISTER_ID = '00000000-0000-0000-0000-000000000002';
const SECOND_SHELTER_LISTER_ID = '00000000-0000-0000-0000-000000000003';
const INDIVIDUAL_LISTER_ID = '00000000-0000-0000-0000-000000000004';
const ADOPTER_ALEX_ID = '00000000-0000-0000-0000-000000000010';
const ADOPTER_SAM_ID = '00000000-0000-0000-0000-000000000011';

const SHELTER = { id: SHELTER_LISTER_ID, displayName: 'Brazos Valley Animal Rescue', contactType: 'shelter' };
const SECOND_SHELTER = { id: SECOND_SHELTER_LISTER_ID, displayName: 'Second Chance Shelter', contactType: 'shelter' };
const INDIVIDUAL = { id: INDIVIDUAL_LISTER_ID, displayName: 'Casey R.', contactType: 'individual' };
const DEMO_LISTER = { id: DEMO_USER_ID, displayName: 'Jordan', contactType: 'individual' };

function daysAgo(days) {
  const d = new Date();
  d.setUTCDate(d.getUTCDate() - days);
  return d;
}

const pets = [
  { name: 'Biscuit', species: 'dog', breed: ['Labrador Retriever'], ageCategory: 'young', ageMonths: 18, size: 'large', sex: 'male',
    tags: ['good with kids', 'high energy', 'friendly'], desc: 'Biscuit loves fetch and long walks. Great with kids and other dogs.',
    photos: ['https://images.dog.ceo/breeds/dane-great/n02109047_22193.jpg', 'https://images.dog.ceo/breeds/spaniel-sussex/n02102480_7831.jpg', 'https://images.dog.ceo/breeds/corgi-cardigan/n02113186_7676.jpg'],
    lat: 30.6320, lng: -96.3300, city: 'College Station', source: { type: 'shelter', label: 'Brazos Valley Animal Rescue', isVerified: true }, lister: SHELTER, days: 3 },
  { name: 'Luna', species: 'cat', breed: ['Domestic Shorthair'], ageCategory: 'adult', ageMonths: 36, size: 'small', sex: 'female',
    tags: ['calm', 'independent'], desc: 'Luna is a chill lap cat who enjoys sunny windowsills.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/1j.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTkxNTA0MA.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cge.jpg'],
    lat: 30.6744, lng: -96.3700, city: 'Bryan', source: { type: 'petfinder', label: null, isVerified: false }, lister: SECOND_SHELTER, days: 7 },
  { name: 'Rocky', species: 'dog', breed: ['Boxer', 'Mix'], ageCategory: 'adult', ageMonths: 48, size: 'large', sex: 'male',
    tags: ['good with kids', 'protective'], desc: 'Rocky is a loyal boxer mix looking for an active family.',
    photos: ['https://images.dog.ceo/breeds/pyrenees/n02111500_2232.jpg', 'https://images.dog.ceo/breeds/mountain-bernese/n02107683_3138.jpg', 'https://images.dog.ceo/breeds/clumber/n02101556_1819.jpg'],
    lat: 30.5400, lng: -96.3600, city: 'Wellborn', source: { type: 'individual', label: null, isVerified: false }, lister: INDIVIDUAL, days: 1 },
  { name: 'Peanut', species: 'dog', breed: ['Chihuahua'], ageCategory: 'senior', ageMonths: 108, size: 'small', sex: 'female',
    tags: ['calm', 'good with seniors'], desc: 'Peanut is a sweet senior who just wants a warm lap.',
    photos: ['https://images.dog.ceo/breeds/african-wild/n02116738_2942.jpg', 'https://images.dog.ceo/breeds/entlebucher/n02108000_2172.jpg', 'https://images.dog.ceo/breeds/malamute/n02110063_6276.jpg'],
    lat: 30.3877, lng: -96.0847, city: 'Navasota', source: { type: 'shelter', label: 'Second Chance Shelter', isVerified: true }, lister: SECOND_SHELTER, days: 14 },
  { name: 'Milo', species: 'cat', breed: ['Tabby'], ageCategory: 'baby', ageMonths: 4, size: 'small', sex: 'male',
    tags: ['playful', 'good with kids'], desc: 'Milo is a curious kitten who loves toys and cardboard boxes.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/tOGSsMx5J.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/e07.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/5kr.jpg'],
    lat: 30.6250, lng: -96.3400, city: 'College Station', source: { type: 'petfinder', label: null, isVerified: false }, lister: SHELTER, days: 2 },
  { name: 'Bella', species: 'dog', breed: ['Poodle Mix'], ageCategory: 'young', ageMonths: 14, size: 'medium', sex: 'female',
    tags: ['friendly', 'hypoallergenic-friendly'], desc: 'Bella is a bouncy poodle mix, great for apartment living.',
    photos: ['https://images.dog.ceo/breeds/retriever-flatcoated/n02099267_3097.jpg', 'https://images.dog.ceo/breeds/retriever-golden/pxl_20220311_055548510.mp_2.jpg', 'https://images.dog.ceo/breeds/pomeranian/n02112018_5560.jpg'],
    lat: 30.7650, lng: -96.3950, city: 'Kurten', source: { type: 'individual', label: null, isVerified: false }, lister: DEMO_LISTER, days: 5 },
  { name: 'Shadow', species: 'cat', breed: ['Domestic Longhair'], ageCategory: 'adult', ageMonths: 30, size: 'medium', sex: 'male',
    tags: ['independent', 'quiet'], desc: 'Shadow prefers a calm home without small children.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/90b.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/793.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/e4b.jpg'],
    lat: 30.5324, lng: -96.6939, city: 'Caldwell', source: { type: 'shelter', label: 'Brazos Valley Animal Rescue', isVerified: true }, lister: SHELTER, days: 9 },
  { name: 'Duke', species: 'dog', breed: ['German Shepherd'], ageCategory: 'adult', ageMonths: 40, size: 'xlarge', sex: 'male',
    tags: ['protective', 'high energy', 'needs training'], medicalConditions: 'Mild hip dysplasia, managed with a daily joint supplement.',
    isVaccinated: true, isSpayedNeutered: true,
    desc: 'Duke is smart and loyal; best with an experienced owner.',
    photos: ['https://images.dog.ceo/breeds/shihtzu/n02086240_4430.jpg', 'https://images.dog.ceo/breeds/spaniel-japanese/n02085782_3121.jpg', 'https://images.dog.ceo/breeds/retriever-flatcoated/n02099267_4906.jpg'],
    lat: 30.8749, lng: -96.5964, city: 'Hearne', source: { type: 'petfinder', label: null, isVerified: false }, lister: SECOND_SHELTER, days: 20 },
  { name: 'Coco', species: 'dog', breed: ['Dachshund'], ageCategory: 'baby', ageMonths: 6, size: 'small', sex: 'female',
    tags: ['playful', 'good with kids'], desc: 'Coco is a spunky dachshund puppy full of energy.',
    photos: ['https://images.dog.ceo/breeds/terrier-tibetan/n02097474_2554.jpg', 'https://images.dog.ceo/breeds/hound-walker/n02089867_1048.jpg', 'https://images.dog.ceo/breeds/clumber/n02101556_1469.jpg'],
    lat: 30.5300, lng: -96.4830, city: 'Snook', source: { type: 'individual', label: null, isVerified: false }, lister: INDIVIDUAL, days: 0 },
  { name: 'Simba', species: 'cat', breed: ['Maine Coon Mix'], ageCategory: 'young', ageMonths: 16, size: 'large', sex: 'male',
    tags: ['friendly', 'good with kids'], desc: 'Simba is a gentle giant who loves attention.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/VwGK1QO3m.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cu0.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/cl7.jpg'],
    lat: 30.6200, lng: -96.3450, city: 'College Station', source: { type: 'shelter', label: 'Brazos Valley Animal Rescue', isVerified: true }, lister: SHELTER, days: 11 },
  { name: 'Zeus', species: 'dog', breed: ['Great Dane'], ageCategory: 'adult', ageMonths: 30, size: 'xlarge', sex: 'male',
    tags: ['calm', 'good with kids'], desc: 'Zeus is a gentle giant despite his size, loves to nap.',
    photos: ['https://images.dog.ceo/breeds/poodle-miniature/n02113712_8595.jpg', 'https://images.dog.ceo/breeds/malinois/n02105162_8841.jpg', 'https://images.dog.ceo/breeds/terrier-dandie/n02096437_140.jpg'],
    lat: 30.7235, lng: -95.5508, city: 'Huntsville', source: { type: 'petfinder', label: null, isVerified: false }, lister: SECOND_SHELTER, days: 25 },
  { name: 'Nala', species: 'cat', breed: ['Siamese Mix'], ageCategory: 'senior', ageMonths: 96, size: 'small', sex: 'female',
    tags: ['calm', 'quiet', 'good with seniors'], medicalConditions: 'Hyperthyroidism, currently medicated and stable.',
    isVaccinated: true, isSpayedNeutered: true, isGoodWithKids: true,
    desc: 'Nala is a sweet senior cat who enjoys quiet company.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/1tb.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/dub.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTY2MjcxMw.jpg'],
    lat: 30.6350, lng: -96.3250, city: 'College Station', source: { type: 'individual', label: null, isVerified: false }, lister: INDIVIDUAL, days: 4 },
  { name: 'Max', species: 'dog', breed: ['Beagle'], ageCategory: 'young', ageMonths: 20, size: 'medium', sex: 'male',
    tags: ['friendly', 'good with kids', 'high energy'], desc: 'Max loves sniffing out adventures on every walk.',
    photos: ['https://images.dog.ceo/breeds/terrier-yorkshire/n02094433_2537.jpg', 'https://images.dog.ceo/breeds/pinscher/coffee_soul_bari024.jpg', 'https://images.dog.ceo/breeds/weimaraner/n02092339_8029.jpg'],
    lat: 30.6800, lng: -96.2950, city: 'Wixon Valley', source: { type: 'shelter', label: 'Second Chance Shelter', isVerified: true }, lister: SECOND_SHELTER, days: 6 },
  { name: 'Willow', species: 'dog', breed: ['Border Collie Mix'], ageCategory: 'young', ageMonths: 22, size: 'medium', sex: 'female',
    tags: ['high energy', 'needs training', 'friendly'], desc: 'Willow is whip-smart and needs an active household.',
    photos: ['https://images.dog.ceo/breeds/spaniel-cocker/n02102318_10818.jpg', 'https://images.dog.ceo/breeds/terrier-norwich/n02094258_1678.jpg', 'https://images.dog.ceo/breeds/entlebucher/n02108000_1547.jpg'],
    lat: 30.4988, lng: -96.0088, city: 'Anderson', source: { type: 'petfinder', label: null, isVerified: false }, lister: SHELTER, days: 8 },
  { name: 'Oliver', species: 'cat', breed: ['Orange Tabby'], ageCategory: 'baby', ageMonths: 5, size: 'small', sex: 'male',
    tags: ['playful', 'good with kids'], desc: 'Oliver is a playful orange tabby kitten looking for a forever home.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/kh.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/vVF7hE-Py.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTg1MTYwNg.jpg'],
    lat: 30.6180, lng: -96.3380, city: 'College Station', source: { type: 'individual', label: null, isVerified: false }, lister: INDIVIDUAL, days: 1 },
  { name: 'Ranger', species: 'dog', breed: ['Australian Shepherd'], ageCategory: 'adult', ageMonths: 42, size: 'large', sex: 'male',
    tags: ['high energy', 'protective', 'friendly'], desc: 'Ranger thrives with hiking, running, and a job to do.',
    photos: ['https://images.dog.ceo/breeds/hound-blood/n02088466_7421.jpg', 'https://images.dog.ceo/breeds/terrier-norwich/n02094258_1823.jpg', 'https://images.dog.ceo/breeds/retriever-golden/n02099601_5679.jpg'],
    lat: 30.3477, lng: -96.5313, city: 'Somerville', source: { type: 'shelter', label: 'Brazos Valley Animal Rescue', isVerified: true }, lister: SHELTER, days: 16 },
  { name: 'Pixel', species: 'cat', breed: ['Russian Blue Mix'], ageCategory: 'young', ageMonths: 15, size: 'small', sex: 'female',
    tags: ['independent', 'quiet', 'calm'], desc: 'Pixel is a quiet, elegant cat who prefers a peaceful home.',
    photos: ['https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/MTU1OTA2MA.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/d08.jpg', 'https://s3.us-west-2.amazonaws.com/cdn2.thecatapi.com/images/9pf.jpg'],
    lat: 30.1669, lng: -96.3977, city: 'Brenham', source: { type: 'petfinder', label: null, isVerified: false }, lister: SECOND_SHELTER, days: 12 },
  { name: 'Copper', species: 'dog', breed: ['Vizsla Mix'], ageCategory: 'young', ageMonths: 17, size: 'medium', sex: 'male',
    tags: ['high energy', 'friendly', 'good with kids'], desc: 'Copper is an athletic, affectionate companion for an active home.',
    photos: ['https://images.dog.ceo/breeds/airedale/n02096051_584.jpg', 'https://images.dog.ceo/breeds/stbernard/n02109525_12041.jpg', 'https://images.dog.ceo/breeds/retriever-golden/n02099601_6105.jpg'],
    lat: 30.7450, lng: -96.0050, city: 'Millican', source: { type: 'individual', label: null, isVerified: false }, lister: INDIVIDUAL, days: 2 }
];

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    await client.query('DELETE FROM chat_messages');
    await client.query('DELETE FROM chat_threads');
    await client.query('DELETE FROM adoption_requests');
    await client.query('DELETE FROM swipe_records');
    await client.query('DELETE FROM pets');
    await client.query('DELETE FROM adoption_preferences');
    await client.query('DELETE FROM users');

    const demoPasswordHash = await bcrypt.hash('password123', 10);
    const unusablePasswordHash = await bcrypt.hash(require('crypto').randomBytes(24).toString('hex'), 10);

    await client.query(
      `INSERT INTO users (id, email, password_hash, display_name, latitude, longitude, city, region, created_at, email_verified)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,true)`,
      [DEMO_USER_ID, 'demo@tailswipe.org', demoPasswordHash, 'Jordan', 30.6280, -96.3344, 'College Station', 'TX', daysAgo(120)]
    );
    await client.query(
      `INSERT INTO adoption_preferences (user_id, species, breeds, age_categories, sizes, max_distance_miles, temperament_tags, open_to_medical_conditions)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [DEMO_USER_ID, ['dog', 'cat'], null, ['baby', 'young', 'adult', 'senior'], ['small', 'medium', 'large', 'xlarge'], 25, null, true]
    );

    await client.query(
      `INSERT INTO users (id, email, password_hash, display_name, latitude, longitude, city, region, created_at, email_verified) VALUES
       ($1,$2,$3,$4,$5,$6,$7,$8,$9,true), ($10,$11,$12,$13,$14,$15,$16,$17,$18,true)`,
      [
        ADOPTER_ALEX_ID, 'alex.kim@example.com', unusablePasswordHash, 'Alex Kim', 30.6260, -96.3320, 'College Station', 'TX', daysAgo(60),
        ADOPTER_SAM_ID, 'sam.rivera@example.com', unusablePasswordHash, 'Sam Rivera', 30.6744, -96.3700, 'Bryan', 'TX', daysAgo(45)
      ]
    );

    let bellaId = null;
    for (const pet of pets) {
      const result = await client.query(
        `INSERT INTO pets (
           name, species, breed, age_category, age_months, size, sex, temperament_tags,
           medical_conditions, is_vaccinated, is_spayed_neutered, is_good_with_kids, is_good_with_other_pets,
           description, photo_urls, latitude, longitude, city, region,
           source_type, source_label, source_is_verified,
           listed_by_id, listed_by_display_name, listed_by_contact_type, status, created_at
         ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27)
         RETURNING id`,
        [
          pet.name, pet.species, pet.breed, pet.ageCategory, pet.ageMonths, pet.size, pet.sex, pet.tags,
          pet.medicalConditions ?? null, !!pet.isVaccinated, !!pet.isSpayedNeutered, !!pet.isGoodWithKids, !!pet.isGoodWithOtherPets,
          pet.desc, pet.photos, pet.lat, pet.lng, pet.city, 'TX',
          pet.source.type, pet.source.label, pet.source.isVerified,
          pet.lister.id, pet.lister.displayName, pet.lister.contactType, 'available', daysAgo(pet.days)
        ]
      );
      if (pet.name === 'Bella') bellaId = result.rows[0].id;
    }

    // Seed two pending requests on the demo user's own listing (Bella) so the Requests
    // tab has something to swipe on right after a fresh sign-in.
    for (const adopterId of [ADOPTER_ALEX_ID, ADOPTER_SAM_ID]) {
      const requestId = `${bellaId}-${adopterId}`;
      await client.query(
        `INSERT INTO adoption_requests (id, pet_id, adopter_id, lister_id, status, is_super)
         VALUES ($1,$2,$3,$4,'pending',false)`,
        [requestId, bellaId, adopterId, DEMO_USER_ID]
      );
    }

    await client.query('COMMIT');
    console.log(`Seeded ${pets.length} pets, 3 users, 2 pending requests.`);
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((error) => {
  console.error('Seed failed:', error);
  process.exit(1);
});
