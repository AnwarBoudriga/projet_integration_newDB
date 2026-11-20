const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');

router.use(requireAuth);

const schema = z.object({
  action: z.string().trim().optional(),
  acteurType: z.enum(['super_admin', 'entreprise', 'candidat', 'systeme']).optional(),
  from: z.coerce.date().optional(),
  to: z.coerce.date().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(200).default(50),
});

// GET /api/admin/logs?action=&acteurType=&from=&to=&page=&limit=
router.get('/', validate(schema, 'query'), async (req, res) => {
  const { action, acteurType, from, to, page, limit } = req.valid;
  const where = [];
  const params = [];
  if (action) { where.push('action = ?'); params.push(action); }
  if (acteurType) { where.push('acteur_type = ?'); params.push(acteurType); }
  if (from) { where.push('created_at >= ?'); params.push(from); }
  if (to) { where.push('created_at <= ?'); params.push(to); }
  const w = where.length ? `WHERE ${where.join(' AND ')}` : '';

  const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM audit_logs ${w}`, params);
  const [rows] = await db.query(
    `SELECT id, acteur_type, acteur_id, action, entite, entite_id, details, ip, created_at
     FROM audit_logs ${w} ORDER BY id DESC LIMIT ? OFFSET ?`,
    [...params, limit, (page - 1) * limit]
  );
  res.json({
    data: rows.map((r) => ({
      id: r.id,
      acteurType: r.acteur_type,
      acteurId: r.acteur_id,
      action: r.action,
      entite: r.entite,
      entiteId: r.entite_id,
      details: r.details,
      ip: r.ip,
      createdAt: r.created_at,
    })),
    pagination: { page, limit, total },
  });
});

module.exports = router;
