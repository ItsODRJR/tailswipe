-- Device token for sending APNs push notifications (new chat messages, accepted requests,
-- new incoming requests). Nullable — not every session has registered for push yet.
ALTER TABLE users ADD COLUMN IF NOT EXISTS apns_device_token TEXT;
