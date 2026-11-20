const crypto = require('crypto');

// Alphabet sans caractères ambigus (0/O, 1/I). 32 caractères => aucun biais modulo.
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

function randomCode(len) {
  const bytes = crypto.randomBytes(len);
  let out = '';
  for (let i = 0; i < len; i++) out += ALPHABET[bytes[i] % ALPHABET.length];
  return out;
}

const generateEnterpriseKey = () => `ENT-${randomCode(8)}`;
const generateCandidateKey = () => `PSY-${randomCode(6)}`;

// On ne stocke jamais la clé en clair: seulement son HMAC-SHA256.
function hashKey(key) {
  return crypto
    .createHmac('sha256', process.env.KEY_SECRET || 'dev-secret')
    .update(String(key).trim().toUpperCase())
    .digest('hex');
}

module.exports = { generateEnterpriseKey, generateCandidateKey, hashKey };
