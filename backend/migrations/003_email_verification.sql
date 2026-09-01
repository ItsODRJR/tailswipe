-- Email verification: signup no longer issues a token immediately. A 6-digit code is
-- emailed and must be submitted to /auth/verify-email before the account is usable.
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_code TEXT;
ALTER TABLE users ADD COLUMN IF NOT EXISTS verification_expires_at TIMESTAMPTZ;

-- Demo/seeded accounts should work without going through the email flow.
UPDATE users SET email_verified = true WHERE email_verified = false;
