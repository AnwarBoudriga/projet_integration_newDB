const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const { requireAuth } = require('../../middlewares/auth');
const AppError = require('../../utils/AppError');
const { logAction } = require('../../utils/audit');

const loginSchema = z.object({
  identifiant: z.string().trim().min(1, 'Identifiant requis'),
  motDePasse: z.string().min(1, 'Mot de passe requis'),
});

// POST /api/admin/auth/login
router.post('/login', validate(loginSchema), async (req, res) => {
  const { identifiant, motDePasse } = req.valid;
  const [rows] = await db.execute('SELECT * FROM super_admins WHERE identifiant = ?', [identifiant]);
  const admin = rows[0];

  const ok = admin && (await bcrypt.compare(motDePasse, admin.mot_de_passe_hash));
  if (!ok) {
    await logAction(req, { action: 'LOGIN_ECHEC', acteurType: 'super_admin', details: { identifiant } });
    throw new AppError(401, 'Identifiant ou mot de passe incorrect.');
  }

  const token = jwt.sign({ sub: admin.id, role: 'super_admin' }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '8h',
  });
  await logAction(req, { action: 'LOGIN', acteurType: 'super_admin', acteurId: admin.id });
  res.json({ token, admin: { id: admin.id, identifiant: admin.identifiant } });
});

// GET /api/admin/auth/me
router.get('/me', requireAuth, async (req, res) => {
  const [rows] = await db.execute('SELECT id, identifiant FROM super_admins WHERE id = ?', [req.user.id]);
  if (!rows[0]) throw new AppError(401, 'Compte introuvable.');
  res.json(rows[0]);
});

module.exports = router;
