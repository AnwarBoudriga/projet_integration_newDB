const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const { signToken, INVITATION_SQL } = require('../../middlewares/auth');
const AppError = require('../../utils/AppError');
const { hashKey } = require('../../utils/keys');
const { logAction } = require('../../utils/audit');

const schema = z.object({ cle: z.string().trim().min(1, 'Clé candidat requise') });

// POST /api/candidat/auth/login   { cle: "PSY-XXXXXX" }
router.post('/login', validate(schema), async (req, res) => {
  const [rows] = await db.execute(`${INVITATION_SQL} WHERE i.cle_hash = ?`, [hashKey(req.valid.cle)]);
  const inv = rows[0];
  if (!inv) {
    await logAction(req, { action: 'CANDIDAT_LOGIN_ECHEC', acteurType: 'candidat' });
    throw new AppError(401, 'Clé candidat invalide.');
  }
  if (inv.ent_statut !== 'actif') throw new AppError(403, 'Accès indisponible.');

  if (inv.statut === 'invite' && inv.expiree) {
    await db.execute(`UPDATE invitations SET statut = 'expire' WHERE id = ? AND statut = 'invite'`, [inv.id]);
    inv.statut = 'expire';
  }
  if (inv.statut === 'expire') throw new AppError(410, 'Cette invitation a expiré.');
  if (inv.statut === 'invite' && inv.test_statut !== 'publie') throw new AppError(409, 'Ce test n’est pas disponible pour le moment.');

  const token = signToken({ sub: inv.id, role: 'candidat' }, '6h');
  await logAction(req, { action: 'CANDIDAT_LOGIN', acteurType: 'candidat', acteurId: inv.id });
  // statut = invite | en_cours | termine  -> l'app sait quel écran afficher
  res.json({ token, candidat: { nom: inv.nom }, statut: inv.statut });
});

module.exports = router;
