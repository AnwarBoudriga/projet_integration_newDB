const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const { signToken, requireEntreprise } = require('../../middlewares/auth');
const AppError = require('../../utils/AppError');
const { hashKey } = require('../../utils/keys');
const { logAction } = require('../../utils/audit');

const schema = z.object({ cle: z.string().trim().min(1, 'Clé entreprise requise') });

// POST /api/entreprise/auth/login   { cle: "ENT-XXXXXXXX" }
router.post('/login', validate(schema), async (req, res) => {
  const [rows] = await db.execute('SELECT id, nom, est_active FROM entreprises WHERE cle_hash = ?', [hashKey(req.valid.cle)]);
  const e = rows[0];
  if (!e) {
    await logAction(req, { action: 'ENTREPRISE_LOGIN_ECHEC', acteurType: 'entreprise' });
    throw new AppError(401, 'Clé entreprise invalide.');
  }
  if (!e.est_active) throw new AppError(403, 'Cette entreprise est désactivée.');
  const token = signToken({ sub: e.id, role: 'entreprise' });
  await logAction(req, { action: 'ENTREPRISE_LOGIN', acteurType: 'entreprise', acteurId: e.id });
  res.json({ token, entreprise: { id: e.id, nom: e.nom } });
});

router.get('/me', requireEntreprise, (req, res) => res.json({ id: req.entreprise.id, nom: req.entreprise.nom }));

module.exports = router;
