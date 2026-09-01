// Converts Postgres rows into the exact JSON shapes the iOS app decodes. This matters a
// lot here: APIClient's JSONDecoder has no keyDecodingStrategy set, so every key below
// must match the Swift property name byte-for-byte (camelCase, including things like
// "photoURLs" and "petID" with a capital ID) — see the Codable structs under
// ios/Tailswipe/Sources/Tailswipe/Models/.

// Swift's `.iso8601` JSONDecoder strategy parses via ISO8601DateFormatter's default
// options, which do NOT include fractional seconds — Date#toISOString() does, so it has
// to be stripped or every date decode on the client fails.
function isoNoMillis(date) {
  if (!date) return null;
  return new Date(date).toISOString().replace(/\.\d{3}Z$/, 'Z');
}

function locationJSON(row, prefix = '') {
  const lat = row[`${prefix}latitude`];
  if (lat === null || lat === undefined) return null;
  return {
    latitude: lat,
    longitude: row[`${prefix}longitude`],
    city: row[`${prefix}city`] ?? null,
    region: row[`${prefix}region`] ?? null
  };
}

function userJSON(row) {
  return {
    id: row.id,
    email: row.email,
    displayName: row.display_name,
    location: locationJSON(row),
    bio: row.bio ?? null,
    avatarImagePath: row.avatar_image_path ?? null,
    createdAt: isoNoMillis(row.created_at)
  };
}

function preferencesJSON(row) {
  return {
    species: row.species,
    breeds: row.breeds ?? null,
    ageCategories: row.age_categories,
    sizes: row.sizes,
    maxDistanceMiles: row.max_distance_miles,
    temperamentTags: row.temperament_tags ?? null,
    openToMedicalConditions: row.open_to_medical_conditions
  };
}

function petJSON(row) {
  return {
    id: row.id,
    name: row.name,
    species: row.species,
    breed: row.breed,
    ageCategory: row.age_category,
    ageMonths: row.age_months ?? null,
    size: row.size,
    sex: row.sex,
    temperamentTags: row.temperament_tags,
    medicalConditions: row.medical_conditions ?? null,
    isVaccinated: row.is_vaccinated,
    isSpayedNeutered: row.is_spayed_neutered,
    isGoodWithKids: row.is_good_with_kids,
    isGoodWithOtherPets: row.is_good_with_other_pets,
    description: row.description,
    photoURLs: row.photo_urls,
    location: locationJSON(row),
    distanceMiles: row.distance_miles ?? null,
    source: {
      type: row.source_type,
      label: row.source_label ?? null,
      isVerified: row.source_is_verified
    },
    listedBy: {
      id: row.listed_by_id,
      displayName: row.listed_by_display_name,
      contactType: row.listed_by_contact_type
    },
    status: row.status,
    createdAt: isoNoMillis(row.created_at)
  };
}

function chatThreadJSON(row) {
  return {
    id: row.id,
    petID: row.pet_id,
    participantUserID: row.participant_user_id,
    listerID: row.lister_id,
    createdAt: isoNoMillis(row.created_at),
    lastMessagePreview: row.last_message_preview ?? null,
    lastMessageAt: row.last_message_at ? isoNoMillis(row.last_message_at) : null
  };
}

function chatMessageJSON(row) {
  return {
    id: row.id,
    threadID: row.thread_id,
    senderID: row.sender_id,
    body: row.body,
    sentAt: isoNoMillis(row.sent_at)
  };
}

function adoptionRequestInfoJSON(requestRow, petRow, adopterRow) {
  return {
    id: requestRow.id,
    pet: petJSON(petRow),
    adopter: userJSON(adopterRow),
    isSuper: requestRow.is_super,
    createdAt: isoNoMillis(requestRow.created_at)
  };
}

module.exports = {
  isoNoMillis,
  userJSON,
  preferencesJSON,
  petJSON,
  chatThreadJSON,
  chatMessageJSON,
  adoptionRequestInfoJSON
};
