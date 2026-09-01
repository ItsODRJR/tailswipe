-- Schema matches the exact JSON shapes the iOS app's API* repositories encode/decode
-- (see ios/Tailswipe/Sources/Tailswipe/Data/{Networking,Repositories}/*.swift). Column
-- names are snake_case here; src/serialize.js maps them to the camelCase keys Swift expects.

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    city TEXT,
    region TEXT,
    bio TEXT,
    avatar_image_path TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS adoption_preferences (
    user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    species TEXT[] NOT NULL DEFAULT '{}',
    breeds TEXT[],
    age_categories TEXT[] NOT NULL DEFAULT '{}',
    sizes TEXT[] NOT NULL DEFAULT '{}',
    max_distance_miles DOUBLE PRECISION NOT NULL DEFAULT 25,
    temperament_tags TEXT[],
    open_to_medical_conditions BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS pets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    species TEXT NOT NULL,
    breed TEXT[] NOT NULL DEFAULT '{}',
    age_category TEXT NOT NULL,
    age_months INT,
    size TEXT NOT NULL,
    sex TEXT NOT NULL,
    temperament_tags TEXT[] NOT NULL DEFAULT '{}',
    medical_conditions TEXT,
    is_vaccinated BOOLEAN NOT NULL DEFAULT false,
    is_spayed_neutered BOOLEAN NOT NULL DEFAULT false,
    is_good_with_kids BOOLEAN NOT NULL DEFAULT false,
    is_good_with_other_pets BOOLEAN NOT NULL DEFAULT false,
    description TEXT NOT NULL DEFAULT '',
    photo_urls TEXT[] NOT NULL DEFAULT '{}',
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    city TEXT,
    region TEXT,
    source_type TEXT NOT NULL,
    source_label TEXT,
    source_is_verified BOOLEAN NOT NULL DEFAULT false,
    -- Listers aren't necessarily registered users (shelters are plain labels in the mock
    -- data), so this is intentionally not a foreign key.
    listed_by_id UUID NOT NULL,
    listed_by_display_name TEXT NOT NULL,
    listed_by_contact_type TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'available',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS swipe_records (
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    decision TEXT NOT NULL,
    decided_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, pet_id)
);

CREATE TABLE IF NOT EXISTS adoption_requests (
    id TEXT PRIMARY KEY,
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    adopter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lister_id UUID NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    is_super BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pet_id UUID NOT NULL REFERENCES pets(id) ON DELETE CASCADE,
    participant_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lister_id UUID NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_message_preview TEXT,
    last_message_at TIMESTAMPTZ,
    UNIQUE (pet_id, participant_user_id)
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES chat_threads(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL,
    body TEXT NOT NULL,
    sent_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_pets_status ON pets(status);
CREATE INDEX IF NOT EXISTS idx_pets_listed_by ON pets(listed_by_id);
CREATE INDEX IF NOT EXISTS idx_swipe_records_user ON swipe_records(user_id);
CREATE INDEX IF NOT EXISTS idx_adoption_requests_lister ON adoption_requests(lister_id, status);
CREATE INDEX IF NOT EXISTS idx_chat_messages_thread ON chat_messages(thread_id);
