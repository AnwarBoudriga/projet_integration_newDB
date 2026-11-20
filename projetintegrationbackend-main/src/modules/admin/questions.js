// Banque de questions (questions où entreprise_id IS NULL)
const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth');
const validate = require('../../middlewares/validate');
const AppError = require('../../utils/AppError');
const { logAction } = require('../../utils/audit');
const { creerQuestionTx, modifierQuestionTx } = require('../../utils/questions');

router.use(requireAuth);

const format = (r) => ({
  id: r.id,
  enonce: r.enonce,
  optionA: r.option_a,
  optionB: r.option_b,
  optionC: r.option_c,
  optionD: r.option_d,
  reponseCorrecte: r.reponse_correcte,
  points: r.points,
  createdAt: r.created_at,
});

const parseId = (v) => {
  const id = Number(v);
  if (!Number.isInteger(id) || id < 1) throw new AppError(400, 'Identifiant invalide.');
  return id;
};

const opt = (label) => z.string().trim().min(1, `${label} requise`).max(255);
const questionSchema = z.object({
  enonce: z.string().trim().min(3, 'Énoncé requis'),
  optionA: opt('Option A'),
  optionB: opt('Option B'),
  optionC: opt('Option C'),
  optionD: opt('Option D'),
  reponseCorrecte: z.enum(['A', 'B', 'C', 'D'], { message: 'Réponse correcte: A, B, C ou D' }),
  points: z.coerce.number().int().min(1, 'Points >= 1').max(1000),
});

const listSchema = z.object({
  search: z.string().trim().optional(),
  page: z.coerce.number().int().min(1).default(1),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

async function getOr404(id) {
  const [rows] = await db.execute('SELECT * FROM v_questions WHERE id = ? AND entreprise_id IS NULL', [id]);
  if (!rows[0]) throw new AppError(404, 'Question introuvable dans la banque.');
  return rows[0];
}

// GET /api/admin/questions
router.get('/', validate(listSchema, 'query'), async (req, res) => {
  const { search, page, limit } = req.valid;
  const params = [];
  let w = 'WHERE entreprise_id IS NULL';
  if (search) {
    w += ' AND enonce LIKE ?';
    params.push(`%${search}%`);
  }
  const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM questions ${w}`, params);
  const [rows] = await db.query(`SELECT * FROM v_questions ${w} ORDER BY id DESC LIMIT ? OFFSET ?`, [
    ...params,
    limit,
    (page - 1) * limit,
  ]);
  res.json({ data: rows.map(format), pagination: { page, limit, total } });
});

// GET /api/admin/questions/:id
router.get('/:id', async (req, res) => res.json(format(await getOr404(parseId(req.params.id)))));

// POST /api/admin/questions
router.post('/', validate(questionSchema), async (req, res) => {
  const q = req.valid;
  const id = await creerQuestionTx({ entrepriseId: null, ...q });
  await logAction(req, { action: 'QUESTION_BANQUE_CREEE', entite: 'question', entiteId: id });
  res.status(201).json(format(await getOr404(id)));
});

// PUT /api/admin/questions/:id
router.put('/:id', validate(questionSchema), async (req, res) => {
  const id = parseId(req.params.id);
  await getOr404(id);
  const q = req.valid;
  await modifierQuestionTx(id, q);
  await logAction(req, { action: 'QUESTION_BANQUE_MODIFIEE', entite: 'question', entiteId: id });
  res.json(format(await getOr404(id)));
});

// DELETE /api/admin/questions/:id  (409 si la question est déjà utilisée dans un test)
router.delete('/:id', async (req, res) => {
  const id = parseId(req.params.id);
  await getOr404(id);
  await db.execute('DELETE FROM questions WHERE id = ? AND entreprise_id IS NULL', [id]);
  await logAction(req, { action: 'QUESTION_BANQUE_SUPPRIMEE', entite: 'question', entiteId: id });
  res.status(204).end();
});

module.exports = router;
