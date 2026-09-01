// Sends the verification-code email via SMTP (Gmail by default). If SMTP_USER/SMTP_PASS
// aren't set, calls are a no-op (with a warning) rather than a hard failure — mirrors how
// backend/src/push.js degrades gracefully without APNs credentials.
const nodemailer = require('nodemailer');

const SMTP_HOST = process.env.SMTP_HOST || 'smtp.gmail.com';
const SMTP_PORT = Number(process.env.SMTP_PORT || 465);
const SMTP_USER = process.env.SMTP_USER;
const SMTP_PASS = process.env.SMTP_PASS;
const MAIL_FROM = process.env.MAIL_FROM || SMTP_USER;

let transporter = null;
let warnedMissingConfig = false;

function isConfigured() {
  return !!(SMTP_USER && SMTP_PASS);
}

function getTransporter() {
  if (!transporter) {
    transporter = nodemailer.createTransport({
      host: SMTP_HOST,
      port: SMTP_PORT,
      secure: SMTP_PORT === 465,
      auth: { user: SMTP_USER, pass: SMTP_PASS }
    });
  }
  return transporter;
}

async function sendVerificationEmail(toEmail, code) {
  if (!isConfigured()) {
    if (!warnedMissingConfig) {
      console.warn('SMTP not configured (SMTP_USER/SMTP_PASS) — verification emails disabled.');
      warnedMissingConfig = true;
    }
    console.log(`[dev] Verification code for ${toEmail}: ${code}`);
    return;
  }
  await getTransporter().sendMail({
    from: `Tailswipe <${MAIL_FROM}>`,
    to: toEmail,
    subject: 'Verify your Tailswipe email',
    text: `Your verification code is ${code}. It expires in 15 minutes.`,
    html: `<p>Your verification code is:</p><p style="font-size:28px;font-weight:bold;letter-spacing:4px;">${code}</p><p>It expires in 15 minutes.</p>`
  });
}

module.exports = { sendVerificationEmail, isConfigured };
