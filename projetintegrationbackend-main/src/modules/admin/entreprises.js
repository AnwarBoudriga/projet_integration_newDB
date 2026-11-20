const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const AppError = require('../../utils/AppError');
const { generateEnterpriseKey, hashKey } = require('../../utils/keys');
const { logAction } = require('../../utils/audit');

router.use(requireAuth);

const COLS = "id, nom, email, secteur, CASE WHEN est_active = 1 THEN 'actif' ELSE 'inactif' END AS statut, (cle_hash IS NOT NULL) AS has_key, created_at";
const format = (r) => ({
  id: r.id,
  nom: r.nom,
  email: r.email,
  secteur: r.secteur,
  statut: r.statut,
  aUneCle: Boolean(r.has_key),
  createdAt: r.created_at,
});

const parseId = (v) => {
  const id = Number(v);
  if (!Number.isInteger(id) || id < 1) throw new AppError(400, 'Identifiant invalide.');
  return id;
};

async function getOr404(id) {
  const [rows] = await db.execute(`SELECT ${COLS} FROM entreprises WHERE id = ?`, [id]);
  if (!rows[0]) throw new AppError(404, 'Entreprise introuvable.');
  return rows[0];
}

const createSchema = z.object({
  nom: z.string().trim().min(2, 'Nom trop court').max(150),
  email: z.string().trim().email('Email invalide').max(150),
  secteur: z.string().trim().max(100).optional().default(''),
});

const listSchema = z.object({
  search: z.string().trim().optional(),
  statut: z.enum(['actif', 'inactif']).optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// GET /api/admin/entreprises?search=&statut=&page=&limit=
router.get('/', validate(listSchema, 'query'), async (req, res) => {
  const { search, statut, page, limit } = req.valid;
  const where = [];
  const params = [];
  if (search) {
    where.push('(nom LIKE ? OR email LIKE ? OR secteur LIKE ?)');
    const like = `%${search}%`;
    params.push(like, like, like);
  }
  if (statut) {
    where.push('est_active = ?');
    params.push(statut === 'actif' ? 1 : 0);
  }
  const w = where.length ? `WHERE ${where.join(' AND ')}` : '';

  const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM entreprises ${w}`, params);
  const [rows] = await db.query(
    `SELECT ${COLS} FROM entreprises ${w} ORDER BY created_at DESC LIMIT ? OFFSET ?`,
    [...params, limit, (page - 1) * limit]
  );
  res.json({ data: rows.map(format), pagination: { page, limit, total } });
});

// GET /api/admin/entreprises/:id
router.get('/:id', async (req, res) => {
  res.json(format(await getOr404(parseId(req.params.id))));
});

// POST /api/admin/entreprises   (nom, email, secteur)
router.post('/', validate(createSchema), async (req, res) => {
  const { nom, email, secteur } = req.valid;
  const [result] = await db.execute('INSERT INTO entreprises (nom, email, secteur) VALUES (?, ?, ?)', [
    nom,
    email,
    secteur,
  ]);
  await logAction(req, { action: 'ENTREPRISE_CREEE', entite: 'entreprise', entiteId: result.insertId, details: { nom, email } });
  res.status(201).json(format(await getOr404(result.insertId)));
});

async function setStatut(req, res, statut) {
  const id = parseId(req.params.id);
  await getOr404(id);
  await db.execute('UPDATE entreprises SET est_active = ? WHERE id = ?', [statut === 'actif' ? 1 : 0, id]);
  await logAction(req, {
    action: statut === 'actif' ? 'ENTREPRISE_ACTIVEE' : 'ENTREPRISE_DESACTIVEE',
    entite: 'entreprise',
    entiteId: id,
  });
  res.json(format(await getOr404(id)));
}

// PATCH /api/admin/entreprises/:id/activer | /desactiver
router.patch('/:id/activer', (req, res) => setStatut(req, res, 'actif'));
router.patch('/:id/desactiver', (req, res) => setStatut(req, res, 'inactif'));

async function issueKey(req, res, regenerate) {
  const id = parseId(req.params.id);
  const entreprise = await getOr404(id);
  if (!regenerate && entreprise.has_key) {
    throw new AppError(409, 'Une clé existe déjà. Utilisez la régénération pour une clé perdue.');
  }
  const cle = generateEnterpriseKey();
  await db.execute('UPDATE entreprises SET cle_hash = ? WHERE id = ?', [hashKey(cle), id]);
  await logAction(req, {
    action: regenerate ? 'CLE_ENTREPRISE_REGENEREE' : 'CLE_ENTREPRISE_GENEREE',
    entite: 'entreprise',
    entiteId: id,
  });
  // La clé en clair n'est renvoyée qu'UNE seule fois.
  res.json({ cle, message: "Copiez cette clé maintenant: elle ne sera plus affichée. L'ancienne clé (si elle existait) est invalide." });
}

// POST /api/admin/entreprises/:id/cle            -> générer (ENT-XXXXXXXX)
// POST /api/admin/entreprises/:id/cle/regenerer  -> régénérer une clé perdue
router.post('/:id/cle', (req, res) => issueKey(req, res, false));
router.post('/:id/cle/regenerer', (req, res) => issueKey(req, res, true));

module.exports = router;
