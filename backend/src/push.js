// APNs (HTTP/2 provider API) push notifications. Entirely optional: if APNS_TEAM_ID /
// APNS_KEY_ID / APNS_KEY_PATH aren't set (or the .p8 file isn't present), every call here
// is a silent no-op (one warning logged) rather than a hard failure — the rest of the app
// works fine without push configured.
const http2 = require('http2');
const jwt = require('jsonwebtoken');
const fs = require('fs');
const path = require('path');
const { pool } = require('./db');

const TEAM_ID = process.env.APNS_TEAM_ID;
const KEY_ID = process.env.APNS_KEY_ID;
const KEY_PATH = process.env.APNS_KEY_PATH;
const BUNDLE_ID = process.env.APNS_BUNDLE_ID || 'org.tailswipe.app';
const HOST = process.env.APNS_ENV === 'production' ? 'api.push.apple.com' : 'api.sandbox.push.apple.com';

let cachedProviderToken = null;
let cachedProviderTokenAt = 0;
let cachedPrivateKey = null;
let warnedMissingConfig = false;

function isConfigured() {
  return !!(TEAM_ID && KEY_ID && KEY_PATH && fs.existsSync(path.resolve(KEY_PATH)));
}

function loadPrivateKey() {
  if (!cachedPrivateKey) {
    cachedPrivateKey = fs.readFileSync(path.resolve(KEY_PATH), 'utf8');
  }
  return cachedPrivateKey;
}

// Apple's provider tokens are valid up to an hour; reuse one instead of signing per-request.
function providerToken() {
  const now = Date.now();
  if (cachedProviderToken && now - cachedProviderTokenAt < 45 * 60 * 1000) {
    return cachedProviderToken;
  }
  cachedProviderToken = jwt.sign(
    { iss: TEAM_ID, iat: Math.floor(now / 1000) },
    loadPrivateKey(),
    { algorithm: 'ES256', header: { alg: 'ES256', kid: KEY_ID } }
  );
  cachedProviderTokenAt = now;
  return cachedProviderToken;
}

function sendPush(deviceToken, { title, body }) {
  return new Promise((resolve, reject) => {
    const client = http2.connect(`https://${HOST}`);
    client.on('error', reject);

    const req = client.request({
      ':method': 'POST',
      ':path': `/3/device/${deviceToken}`,
      authorization: `bearer ${providerToken()}`,
      'apns-topic': BUNDLE_ID,
      'apns-push-type': 'alert',
      'content-type': 'application/json'
    });

    let responseBody = '';
    req.setEncoding('utf8');
    req.on('data', (chunk) => { responseBody += chunk; });
    req.on('end', () => {
      client.close();
      resolve(responseBody);
    });
    req.on('error', (err) => {
      client.close();
      reject(err);
    });
    req.write(JSON.stringify({ aps: { alert: { title, body }, sound: 'default' } }));
    req.end();
  });
}

async function sendToUser(userId, notification) {
  if (!isConfigured()) {
    if (!warnedMissingConfig) {
      console.warn('APNs not configured (APNS_TEAM_ID/APNS_KEY_ID/APNS_KEY_PATH) — push notifications disabled.');
      warnedMissingConfig = true;
    }
    return;
  }
  const result = await pool.query('SELECT apns_device_token FROM users WHERE id = $1', [userId]);
  const token = result.rows[0]?.apns_device_token;
  if (!token) return;
  try {
    await sendPush(token, notification);
  } catch (err) {
    console.error('APNs send failed:', err);
  }
}

async function notifyNewMessage({ recipientUserId, senderId, body }) {
  const senderResult = await pool.query('SELECT display_name FROM users WHERE id = $1', [senderId]);
  const senderName = senderResult.rows[0]?.display_name || 'Someone';
  await sendToUser(recipientUserId, { title: senderName, body });
}

async function notifyRequestAccepted({ recipientUserId, petName }) {
  await sendToUser(recipientUserId, {
    title: 'You matched! 🎉',
    body: `Your request for ${petName} was accepted — say hello!`
  });
}

async function notifyNewRequest({ recipientUserId, petName, isSuper }) {
  await sendToUser(recipientUserId, {
    title: isSuper ? 'New super interest! ⭐' : 'New interest',
    body: `Someone is interested in adopting ${petName}.`
  });
}

module.exports = { notifyNewMessage, notifyRequestAccepted, notifyNewRequest, isConfigured };
