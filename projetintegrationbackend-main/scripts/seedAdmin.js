// Crée (ou met à jour) le compte Super Admin: npm run seed:admin
require('dotenv').config();
const bcrypt = require('bcryptjs');
const db = require('../src/config/db');

(async () => {
  const identifiant = process.env.ADMIN_IDENTIFIANT || 'superadmin';
  const password = process.env.ADMIN_PASSWORD;
  if (!password || password.length < 8) {
    console.error('ADMIN_PASSWORD manquant ou trop court (min 8) dans .env');
    process.exit(1);
  }
  const nom = process.env.ADMIN_NOM || 'Super Administrateur';
  const email = process.env.ADMIN_EMAIL || 'admin@psytech.local';
  const hash = await bcrypt.hash(password, 12);
  await db.execute(
    `INSERT INTO super_admins (identifiant, nom, email, mot_de_passe_hash) VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE nom = VALUES(nom), email = VALUES(email), mot_de_passe_hash = VALUES(mot_de_passe_hash)`,
    [identifiant, nom, email, hash]
  );
  console.log(`Super Admin "${identifiant}" prêt.`);
  process.exit(0);
})();
