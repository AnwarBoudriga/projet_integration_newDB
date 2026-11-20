// Données de démonstration pour tester les 3 modules.
//   npm run seed:demo           (refuse si des entreprises existent déjà)
//   npm run seed:demo:reset     (EFFACE toutes les données sauf le Super Admin, puis recrée)
require('dotenv').config();
const db = require('../src/config/db');
const { generateEnterpriseKey, generateCandidateKey, hashKey } = require('../src/utils/keys');
const { creerQuestion } = require('../src/utils/questions');

const LETTERS = ['A', 'B', 'C', 'D'];
const QUESTIONS = [
  ['Quel nombre complète la suite : 3, 6, 12, 24, ?', ['30', '36', '48', '54'], 'C'],
  ['Quel nombre complète la suite : 2, 4, 8, 16, ?', ['24', '30', '34', '32'], 'D'],
  ['Quel nombre complète la suite : 1, 4, 9, 16, ?', ['20', '25', '24', '36'], 'B'],
  ['Quel nombre complète la suite : 5, 10, 20, 40, ?', ['60', '70', '90', '80'], 'D'],
  ['Quel nombre complète la suite : 100, 90, 80, 70, ?', ['60', '55', '50', '65'], 'A'],
  ['Quel nombre complète la suite : 1, 1, 2, 3, 5, ?', ['7', '8', '9', '10'], 'B'],
  ['Quel nombre complète la suite : 2, 6, 18, 54, ?', ['108', '144', '162', '180'], 'C'],
  ['Quel nombre complète la suite : 7, 14, 21, 28, ?', ['32', '35', '36', '42'], 'B'],
  ['Quel nombre complète la suite : 64, 32, 16, 8, ?', ['2', '4', '6', '12'], 'B'],
  ['Quel nombre complète la suite : 1, 3, 6, 10, 15, ?', ['18', '20', '25', '21'], 'D'],
];

async function reset() {
  const conn = await db.getConnection();
  try {
    await conn.query('SET FOREIGN_KEY_CHECKS = 0');
    for (const t of ['reponses', 'passages', 'invitations', 'candidats', 'test_questions', 'tests', 'choix', 'questions', 'entreprises', 'audit_logs']) {
      await conn.query(`TRUNCATE TABLE ${t}`);
    }
    await conn.query('SET FOREIGN_KEY_CHECKS = 1');
  } finally {
    conn.release();
  }
}

const minutes = (m) => new Date(Date.now() + m * 60000);

(async () => {
  const [[{ n }]] = await db.query('SELECT COUNT(*) AS n FROM entreprises');
  if (process.argv.includes('--reset')) await reset();
  else if (n > 0) {
    console.error('La base contient déjà des données. Utilisez: npm run seed:demo:reset (efface tout sauf le Super Admin).');
    process.exit(1);
  }

  // --- Entreprises ---------------------------------------------------
  const ent = async (nom, email, secteur, statut, withKey) => {
    const cle = withKey ? generateEnterpriseKey() : null;
    const [r] = await db.execute(
      'INSERT INTO entreprises (nom, email, secteur, est_active, cle_hash) VALUES (?,?,?,?,?)',
      [nom, email, secteur, statut === 'actif' ? 1 : 0, cle ? hashKey(cle) : null]
    );
    return { id: r.insertId, nom, cle, statut };
  };
  const acme = await ent('Acme Tunisie', 'rh@acme.tn', 'Industrie', 'actif', true);
  const tech = await ent('TechSud', 'contact@techsud.tn', 'Informatique', 'inactif', true);
  const nova = await ent('Nova Conseil', 'hr@nova.tn', 'Conseil', 'actif', false);

  // --- Banque de questions (entreprise_id = NULL) ----------------------
  const qIds = [];
  for (const [enonce, o, rep] of QUESTIONS) {
    qIds.push(
      await creerQuestion(db, {
        entrepriseId: null, enonce, optionA: o[0], optionB: o[1], optionC: o[2], optionD: o[3], reponseCorrecte: rep, points: 1,
      })
    );
  }

  // --- Tests d'Acme ----------------------------------------------------
  const [t1] = await db.execute(
    `INSERT INTO tests (entreprise_id, titre, description, duree_minutes, categorie, score_minimum, afficher_score, est_publie)
     VALUES (?,?,?,?,?,?,?,?)`,
    [acme.id, 'Raisonnement logique', 'Identifiez des relations logiques et complétez des suites en choisissant une réponse parmi quatre propositions.', 30, 'Logique', 60, 1, 1]
  );
  const testId = t1.insertId;
  for (let i = 0; i < qIds.length; i++) {
    await db.execute('INSERT INTO test_questions (test_id, question_id, position) VALUES (?,?,?)', [testId, qIds[i], i + 1]);
  }
  await db.execute(
    `INSERT INTO tests (entreprise_id, titre, description, duree_minutes, categorie, score_minimum, afficher_score, est_publie)
     VALUES (?,?,?,?,?,?,?,?)`,
    [acme.id, 'Aptitude numérique (brouillon)', 'Test en cours de préparation.', 20, 'Numérique', 0, 0, 0]
  );

  // --- Candidats invités (candidat + invitation + passage si commencé) --------
  const cands = [];
  const inv = async (nom, email, statut, expiration, debut = null) => {
    const cle = generateCandidateKey();
    const [c] = await db.execute('INSERT INTO candidats (entreprise_id, nom, email) VALUES (?,?,?)', [acme.id, nom, email]);
    const [r] = await db.execute(
      `INSERT INTO invitations (entreprise_id, test_id, candidat_id, cle_hash, expiration, statut, email_envoye_at)
       VALUES (?,?,?,?,?,?,NOW())`,
      [acme.id, testId, c.insertId, hashKey(cle), expiration, statut]
    );
    let passageId = null;
    if (debut) {
      const [p] = await db.execute('INSERT INTO passages (invitation_id, date_debut) VALUES (?, ?)', [r.insertId, debut]);
      passageId = p.insertId;
    }
    cands.push({ nom, statut, cle });
    return { id: r.insertId, passageId };
  };
  const repondre = async (passageId, questionId, lettre) => {
    const [[ch]] = await db.query('SELECT id, est_correct FROM choix WHERE question_id = ? AND lettre = ?', [questionId, lettre]);
    await db.execute('INSERT INTO reponses (passage_id, question_id, choix_id, est_correcte) VALUES (?,?,?,?)', [
      passageId, questionId, ch.id, ch.est_correct,
    ]);
  };
  const sami = await inv('Sami Ben Ali', 'sami@mail.tn', 'termine', minutes(7 * 1440), minutes(-60));
  const rim = await inv('Rim Trabelsi', 'rim@mail.tn', 'en_cours', minutes(7 * 1440), minutes(-10));
  await inv('Karim Jlassi', 'karim@mail.tn', 'invite', minutes(7 * 1440));
  await inv('Leila Mansour', 'leila@mail.tn', 'expire', minutes(-1440));

  // Sami: 7 bonnes réponses sur 10 -> réussi (score minimum 6), soumis après 25 minutes
  let score = 0;
  for (let i = 0; i < qIds.length; i++) {
    const good = QUESTIONS[i][2];
    const choix = i < 7 ? good : LETTERS[(LETTERS.indexOf(good) + 1) % 4];
    if (choix === good) score++;
    await repondre(sami.passageId, qIds[i], choix);
  }
  await db.execute(
    'UPDATE passages SET date_soumission = ?, score = ?, score_max = ?, est_reussi = ? WHERE id = ?',
    [minutes(-35), score, qIds.length, score * 100 >= 60 * qIds.length ? 1 : 0, sami.passageId]
  );
  // Rim: 3 réponses déjà données (test en cours)
  for (let i = 0; i < 3; i++) await repondre(rim.passageId, qIds[i], QUESTIONS[i][2]);

  // --- Journal d'activité ------------------------------------------------
  const log = (type, id, action, entite, entiteId) =>
    db.execute('INSERT INTO audit_logs (acteur_type, acteur_id, action, entite, entite_id) VALUES (?,?,?,?,?)', [type, id, action, entite, entiteId]);
  for (const e of [acme, tech, nova]) await log('super_admin', 1, 'ENTREPRISE_CREEE', 'entreprise', e.id);
  await log('super_admin', 1, 'CLE_ENTREPRISE_GENEREE', 'entreprise', acme.id);
  await log('super_admin', 1, 'ENTREPRISE_DESACTIVEE', 'entreprise', tech.id);
  await log('entreprise', acme.id, 'TEST_PUBLIE', 'test', testId);
  await log('candidat', sami.id, 'TEST_SOUMIS', 'invitation', sami.id);

  console.log('\n=== Données de démo créées ===\n');
  console.log('CLÉS ENTREPRISE (login RH, à copier maintenant):');
  for (const e of [acme, tech, nova]) console.log(`  ${e.nom.padEnd(14)} [${e.statut}]  ${e.cle || '(pas de clé: à générer par le Super Admin)'}`);
  console.log('\nCLÉS CANDIDAT (login Candidat), test "Raisonnement logique" d\'Acme:');
  for (const c of cands) console.log(`  ${c.nom.padEnd(14)} [${c.statut}]  ${c.cle}`);
  console.log(`\nSami a terminé avec ${score}/${qIds.length}.  Super Admin: npm run seed:admin\n`);
  process.exit(0);
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
