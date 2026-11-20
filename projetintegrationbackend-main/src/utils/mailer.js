const nodemailer = require('nodemailer');

let transporter = null;
function getTransporter() {
  if (transporter) return transporter;
  if (!process.env.SMTP_HOST) return null;
  transporter = nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === 'true',
    auth: process.env.SMTP_USER ? { user: process.env.SMTP_USER, pass: process.env.SMTP_PASS } : undefined,
  });
  return transporter;
}

/** Envoie un email. Sans SMTP configuré: affiche le mail dans la console (mode dev). */
async function sendMail({ to, subject, text }) {
  const t = getTransporter();
  if (!t) {
    console.log(`\n[mail simulé] À: ${to}\nSujet: ${subject}\n${text}\n`);
    return false;
  }
  try {
    await t.sendMail({ from: process.env.MAIL_FROM || 'PsyTech Pro <no-reply@psytech.local>', to, subject, text });
    return true;
  } catch (e) {
    console.error('[mail] échec:', e.message);
    return false;
  }
}
module.exports = { sendMail };
