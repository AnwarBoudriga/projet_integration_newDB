const express = require('express');
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const AppError = require('../../utils/AppError');
const { logAction } = require('../../utils/audit');
const { creerQuestion, modifierQuestionTx } = require('../../utils/questions');
const { parseId, getTest, assertEditable } = require('./helpers');

const testQuestions = express.Router({ mergeParams: true }); // /tests/:testId/questions
const banque = express.Router(); // /banque

const opt = (l) => z.string().trim().min(1, `${l} requise`).max(255);
const questionSchema = z.object({
  enonce: z.string().trim().min(3, 'Énoncé requis'),
  optionA: opt('Option A'),
  optionB: opt('Option B'),
  optionC: opt('Option C'),
  optionD: opt('Option D'),
  reponseCorrecte: z.enum(['A', 'B', 'C', 'D'], { message: 'Réponse correcte: A, B, C ou D' }),
  points: z.coerce.number().int().min(1, 'Points >= 1').max(1000),
});

const fmtQ = (r) => ({
  id: r.id,
  position: r.position,
  enonce: r.enonce,
  optionA: r.option_a,
  optionB: r.option_b,
  optionC: r.option_c,
  optionD: r.option_d,
  reponseCorrecte: r.reponse_correcte,
  points: r.points,
  source: r.entreprise_id === null ? 'banque' : 'entreprise',
});

const liste = async (testId) => {
  const [rows] = await db.query(
    `SELECT q.*, tq.position FROM test_questions tq JOIN v_questions q ON q.id = tq.question_id
     WHERE tq.test_id = ? ORDER BY tq.position, q.id`,
    [testId]
  );
  return { data: rows.map(fmtQ) };
};

const ecrireOrdre = async (conn, testId, ids) => {
  for (let i = 0; i < ids.length; i++) {
    await conn.execute('UPDATE test_questions SET position = ? WHERE test_id = ? AND question_id = ?', [i + 1, testId, ids[i]]);
  }
};

const testDe = (req) => getTest(req.user.id, parseId(req.params.testId, 'Test'));

// GET /api/entreprise/tests/:testId/questions
testQuestions.get('/', async (req, res) => {
  const test = await testDe(req);
  res.json(await liste(test.id));
});

// POST .../questions   -> crée une question propre à l'entreprise et l'ajoute à la fin
testQuestions.post('/', validate(questionSchema), async (req, res) => {
  const test = await testDe(req);
  await assertEditable(test);
  const q = req.valid;
  const conn = await db.getConnection();
  let id;
  try {
    await conn.beginTransaction();
    id = await creerQuestion(conn, { entrepriseId: req.user.id, ...q });
    const [[m]] = await conn.query('SELECT COALESCE(MAX(position), 0) + 1 AS p FROM test_questions WHERE test_id = ?', [test.id]);
    await conn.execute('INSERT INTO test_questions (test_id, question_id, position) VALUES (?,?,?)', [test.id, id, m.p]);
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  await logAction(req, { action: 'QUESTION_AJOUTEE', entite: 'test', entiteId: test.id, details: { questionId: id } });
  res.status(201).json(await liste(test.id));
});

// POST .../questions/banque   { questionIds: [1,2,3] }  -> "Utiliser la sélection" de la banque
testQuestions.post('/banque', validate(z.object({ questionIds: z.array(z.coerce.number().int().min(1)).min(1).max(100) })), async (req, res) => {
  const test = await testDe(req);
  await assertEditable(test);
  const ids = [...new Set(req.valid.questionIds)];
  const [bank] = await db.query('SELECT id FROM questions WHERE entreprise_id IS NULL AND id IN (?)', [ids]);
  if (bank.length !== ids.length) throw new AppError(404, 'Certaines questions ne sont pas dans la banque.');
  const [have] = await db.query('SELECT question_id FROM test_questions WHERE test_id = ?', [test.id]);
  const deja = new Set(have.map((h) => h.question_id));
  let pos = have.length;
  for (const id of ids) {
    if (deja.has(id)) continue;
    await db.execute('INSERT INTO test_questions (test_id, question_id, position) VALUES (?,?,?)', [test.id, id, ++pos]);
  }
  await logAction(req, { action: 'QUESTIONS_BANQUE_AJOUTEES', entite: 'test', entiteId: test.id, details: { ids } });
  res.status(201).json(await liste(test.id));
});

// PUT .../questions/:qid   -> modifier une question propre (pas celles de la banque)
testQuestions.put('/:qid', validate(questionSchema), async (req, res) => {
  const test = await testDe(req);
  await assertEditable(test);
  const qid = parseId(req.params.qid, 'Question');
  const [rows] = await db.execute(
    `SELECT q.* FROM questions q JOIN test_questions tq ON tq.question_id = q.id WHERE tq.test_id = ? AND q.id = ?`,
    [test.id, qid]
  );
  if (!rows[0]) throw new AppError(404, 'Question introuvable dans ce test.');
  if (rows[0].entreprise_id === null) throw new AppError(403, 'Question de la banque: non modifiable (elle appartient au Super Administrateur).');
  const q = req.valid;
  await modifierQuestionTx(qid, q);
  await logAction(req, { action: 'QUESTION_MODIFIEE', entite: 'question', entiteId: qid });
  res.json(await liste(test.id));
});

// DELETE .../questions/:qid   -> retire du test (et supprime la question si elle est propre à l'entreprise)
testQuestions.delete('/:qid', async (req, res) => {
  const test = await testDe(req);
  await assertEditable(test);
  const qid = parseId(req.params.qid, 'Question');
  const [rows] = await db.execute('SELECT q.entreprise_id FROM questions q JOIN test_questions tq ON tq.question_id = q.id WHERE tq.test_id = ? AND q.id = ?', [test.id, qid]);
  if (!rows[0]) throw new AppError(404, 'Question introuvable dans ce test.');
  await db.execute('DELETE FROM test_questions WHERE test_id = ? AND question_id = ?', [test.id, qid]);
  if (rows[0].entreprise_id !== null) {
    const [[u]] = await db.execute('SELECT COUNT(*) AS n FROM test_questions WHERE question_id = ?', [qid]);
    if (Number(u.n) === 0) await db.execute('DELETE FROM questions WHERE id = ?', [qid]);
  }
  const [rest] = await db.query('SELECT question_id FROM test_questions WHERE test_id = ? ORDER BY position, question_id', [test.id]);
  await ecrireOrdre(db, test.id, rest.map((r) => r.question_id));
  await logAction(req, { action: 'QUESTION_RETIREE', entite: 'test', entiteId: test.id, details: { questionId: qid } });
  res.json(await liste(test.id));
});

// POST .../questions/:qid/monter | /descendre
async function deplacer(req, res, delta) {
  const test = await testDe(req);
  await assertEditable(test);
  const qid = parseId(req.params.qid, 'Question');
  const [rows] = await db.query('SELECT question_id FROM test_questions WHERE test_id = ? ORDER BY position, question_id', [test.id]);
  const ids = rows.map((r) => r.question_id);
  const i = ids.indexOf(qid);
  if (i < 0) throw new AppError(404, 'Question introuvable dans ce test.');
  const j = i + delta;
  if (j >= 0 && j < ids.length) {
    [ids[i], ids[j]] = [ids[j], ids[i]];
    await ecrireOrdre(db, test.id, ids);
  }
  res.json(await liste(test.id));
}
testQuestions.post('/:qid/monter', (req, res) => deplacer(req, res, -1));
testQuestions.post('/:qid/descendre', (req, res) => deplacer(req, res, 1));

// GET /api/entreprise/banque?search=&page=&limit=   (questions créées par le Super Admin)
banque.get('/', async (req, res) => {
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.min(100, Math.max(1, Number(req.query.limit) || 50));
  const search = String(req.query.search || '').trim();
  const where = `WHERE entreprise_id IS NULL ${search ? 'AND enonce LIKE ?' : ''}`;
  const params = search ? [`%${search}%`] : [];
  const [[{ total }]] = await db.query(`SELECT COUNT(*) AS total FROM questions ${where}`, params);
  const [rows] = await db.query(`SELECT * FROM v_questions ${where} ORDER BY id DESC LIMIT ? OFFSET ?`, [...params, limit, (page - 1) * limit]);
  res.json({ data: rows.map(fmtQ), pagination: { page, limit, total: Number(total) } });
});

module.exports = { testQuestions, banque };
