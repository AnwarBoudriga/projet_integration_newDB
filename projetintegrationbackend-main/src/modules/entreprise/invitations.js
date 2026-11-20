const router = require('express').Router();
const crypto = require('crypto');
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const AppError = require('../../utils/AppError');
const { generateCandidateKey, hashKey } = require('../../utils/keys');
const { logAction } = require('../../utils/audit');
const { sendMail } = require('../../utils/mailer');
const { parseCsv } = require('../../utils/csv');
const { parseId, getTest } = require('./helpers');

const emailOk = (e) => z.string().email().max(150).safeParse(e).success;

async function testPublie(req, testId) {
  const test = await getTest(req.user.id, testId);
  if (test.statut !== 'publie') throw new AppError(409, 'Le test doit être publié pour inviter des candidats.');
  return test;
}

/** Retourne l'id du Candidat (même entreprise + même email), en le créant s'il n'existe pas encore. */
async function trouverOuCreerCandidat(entrepriseId, nom, email) {
  const [r] = await db.execute(
    `INSERT INTO candidats (entreprise_id, nom, email) VALUES (?,?,?)
     ON DUPLICATE KEY UPDATE id = LAST_INSERT_ID(id)`,
    [entrepriseId, nom, email]
  );
  return r.insertId;
}

/** Crée l'invitation (clé PSY-XXXXXX unique, hashée en base). */
async function creer({ entrepriseId, test, nom, email, jours, lot = null }) {
  const candidatId = await trouverOuCreerCandidat(entrepriseId, nom, email);
  for (let essai = 0; essai < 5; essai++) {
    const cle = generateCandidateKey();
    try {
      const [r] = await db.execute(
        `INSERT INTO invitations (entreprise_id, test_id, candidat_id, cle_hash, expiration, lot_import)
         VALUES (?,?,?,?, DATE_ADD(NOW(), INTERVAL ? DAY), ?)`,
        [entrepriseId, test.id, candidatId, hashKey(cle), jours, lot]
      );
      return { id: r.insertId, cle };
    } catch (e) {
      if (e.code !== 'ER_DUP_ENTRY') throw e;
    }
  }
  throw new AppError(500, 'Impossible de générer une clé unique.');
}

async function envoyerEmail(req, test, inv, nom, email) {
  const [[row]] = await db.execute(`SELECT DATE_FORMAT(expiration, '%d/%m/%Y %H:%i') AS exp FROM invitations WHERE id = ?`, [inv.id]);
  const lien = process.env.CANDIDAT_URL ? `\nAccès: ${process.env.CANDIDAT_URL}\n` : '';
  const ok = await sendMail({
    to: email,
    subject: `Invitation au test « ${test.titre} »`,
    text:
      `Bonjour ${nom},\n\n${req.entreprise.nom} vous invite à passer le test « ${test.titre} » (${test.duree_minutes} minutes).\n\n` +
      `Votre clé candidat: ${inv.cle}\nValable jusqu'au ${row.exp}.\n${lien}\nBonne chance !`,
  });
  if (ok) await db.execute('UPDATE invitations SET email_envoye_at = NOW() WHERE id = ?', [inv.id]);
  return ok;
}

const invSchema = z.object({
  nom: z.string().trim().min(2, 'Nom requis').max(150),
  email: z.string().trim().email('Email invalide').max(150),
  testId: z.coerce.number().int().min(1),
  expirationJours: z.coerce.number().int().min(1).max(90),
});

// POST /api/entreprise/invitations   { nom, email, testId, expirationJours }
router.post('/', validate(invSchema), async (req, res) => {
  const { nom, email, testId, expirationJours } = req.valid;
  const test = await testPublie(req, testId);
  const inv = await creer({ entrepriseId: req.user.id, test, nom, email, jours: expirationJours });
  const emailEnvoye = await envoyerEmail(req, test, inv, nom, email);
  await logAction(req, { action: 'INVITATION_CREEE', entite: 'invitation', entiteId: inv.id, details: { testId } });
  // La clé en clair n'est renvoyée qu'ici (elle est hashée en base).
  res.status(201).json({ id: inv.id, nom, email, cle: inv.cle, emailEnvoye });
});

const importSchema = z.object({
  testId: z.coerce.number().int().min(1),
  expirationJours: z.coerce.number().int().min(1).max(90),
  csv: z.string().min(3).max(2_000_000),
});

// POST /api/entreprise/invitations/import   { testId, expirationJours, csv: "nom,email\n..." }
router.post('/import', validate(importSchema), async (req, res) => {
  const { testId, expirationJours, csv } = req.valid;
  const test = await testPublie(req, testId);
  const rows = parseCsv(csv);
  if (!rows.length) throw new AppError(400, 'Fichier CSV vide.');

  let iNom = 0;
  let iEmail = 1;
  let start = 0;
  const head = rows[0].map((c) => c.trim().toLowerCase());
  const emailHeads = ['email', 'e-mail', 'mail'];
  if (head.some((h) => emailHeads.includes(h))) {
    iEmail = head.findIndex((h) => emailHeads.includes(h));
    iNom = head.findIndex((h) => ['nom', 'name', 'nom complet', 'candidat'].includes(h));
    if (iNom < 0) iNom = iEmail === 0 ? 1 : 0;
    start = 1;
  }
  const data = rows.slice(start);
  if (!data.length) throw new AppError(400, 'Aucune ligne de données dans le CSV.');
  if (data.length > 500) throw new AppError(400, 'Maximum 500 candidats par import.');

  const lot = crypto.randomBytes(8).toString('hex');
  const crees = [];
  const erreurs = [];
  const vus = new Set();
  for (let k = 0; k < data.length; k++) {
    const ligne = start + k + 1;
    const nom = (data[k][iNom] || '').trim();
    const email = (data[k][iEmail] || '').trim().toLowerCase();
    if (nom.length < 2) { erreurs.push({ ligne, email, message: 'Nom manquant.' }); continue; }
    if (!emailOk(email)) { erreurs.push({ ligne, email, message: 'Email invalide.' }); continue; }
    if (vus.has(email)) { erreurs.push({ ligne, email, message: 'Email en double dans le fichier.' }); continue; }
    vus.add(email);
    const inv = await creer({ entrepriseId: req.user.id, test, nom, email, jours: expirationJours, lot });
    crees.push({ id: inv.id, nom, email, cle: inv.cle, _inv: inv });
  }
  await Promise.allSettled(crees.map((c) => envoyerEmail(req, test, c._inv, c.nom, c.email)));
  await logAction(req, { action: 'INVITATIONS_IMPORTEES', entite: 'test', entiteId: test.id, details: { lot, crees: crees.length, erreurs: erreurs.length } });
  res.status(201).json({ lot, crees: crees.map(({ _inv, ...c }) => c), erreurs });
});

const listSchema = z.object({
  testId: z.coerce.number().int().min(1).optional(),
  statut: z.enum(['invite', 'en_cours', 'termine', 'expire']).optional(),
  search: z.string().trim().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

// GET /api/entreprise/invitations?testId=&statut=&search=&page=&limit=   -> "Candidats invités"
router.get('/', validate(listSchema, 'query'), async (req, res) => {
  const { testId, statut, search, page, limit } = req.valid;
  const where = [];
  const params = [req.user.id];
  if (testId) { where.push('x.test_id = ?'); params.push(testId); }
  if (statut) { where.push('x.statut = ?'); params.push(statut); }
  if (search) { where.push('(x.nom LIKE ? OR x.email LIKE ?)'); params.push(`%${search}%`, `%${search}%`); }
  const w = where.length ? `WHERE ${where.join(' AND ')}` : '';
  // statut effectif: une invitation jamais utilisée et dépassée est "expire"
  const base = `
    SELECT i.id, c.nom, c.email, i.expiration, i.created_at, i.email_envoye_at, t.id AS test_id, t.titre AS test_titre,
           CASE WHEN i.statut = 'invite' AND i.expiration < NOW() THEN 'expire' ELSE i.statut END AS statut
    FROM invitations i
    JOIN candidats c ON c.id = i.candidat_id
    JOIN tests t ON t.id = i.test_id
    WHERE i.entreprise_id = ?`;
  const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM (${base}) x ${w}`, params);
  const [rows] = await db.query(`SELECT * FROM (${base}) x ${w} ORDER BY x.id DESC LIMIT ? OFFSET ?`, [...params, limit, (page - 1) * limit]);
  res.json({
    data: rows.map((r) => ({
      id: r.id, nom: r.nom, email: r.email, testId: r.test_id, test: r.test_titre,
      expiration: r.expiration, statut: r.statut, emailEnvoye: r.email_envoye_at != null, createdAt: r.created_at,
    })),
    pagination: { page, limit, total: Number(total) },
  });
});

// DELETE /api/entreprise/invitations/:id   (seulement si le candidat n'a pas commencé)
router.delete('/:id', async (req, res) => {
  const id = parseId(req.params.id);
  const [rows] = await db.execute('SELECT statut, candidat_id FROM invitations WHERE id = ? AND entreprise_id = ?', [id, req.user.id]);
  if (!rows[0]) throw new AppError(404, 'Invitation introuvable.');
  if (rows[0].statut !== 'invite') throw new AppError(409, 'Le candidat a déjà commencé: suppression impossible.');
  await db.execute('DELETE FROM invitations WHERE id = ?', [id]);
  // Le candidat qui n'a plus aucune invitation est supprimé aussi
  await db.execute(
    'DELETE FROM candidats WHERE id = ? AND NOT EXISTS (SELECT 1 FROM invitations WHERE candidat_id = ?)',
    [rows[0].candidat_id, rows[0].candidat_id]
  );
  await logAction(req, { action: 'INVITATION_SUPPRIMEE', entite: 'invitation', entiteId: id });
  res.status(204).end();
});

module.exports = router;
