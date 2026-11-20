const router = require('express').Router();
const { z } = require('zod');
const db = require('../../config/db');
const validate = require('../../middlewares/validate');
const AppError = require('../../utils/AppError');
const { logAction } = require('../../utils/audit');
const { creerQuestion } = require('../../utils/questions');
const { parseId, TEST_SELECT, fmtTest, getTest } = require('./helpers');

const testSchema = z.object({
  titre: z.string().trim().min(2, 'Titre requis').max(200),
  description: z.string().trim().max(5000).optional().default(''),
  dureeMinutes: z.coerce.number().int().min(1, 'Durée >= 1 minute').max(600),
  categorie: z.string().trim().max(100).optional().default(''),
  scoreMinimum: z.coerce.number().int().min(0, 'Score minimum entre 0 et 100').max(100, 'Score minimum entre 0 et 100').optional().default(0), // en %
  afficherScore: z.boolean().optional().default(false),
});

// GET /api/entreprise/tests?statut=publie|brouillon
router.get('/', async (req, res) => {
  const statut = ['publie', 'brouillon'].includes(req.query.statut) ? req.query.statut : null;
  const [rows] = await db.query(
    `${TEST_SELECT} WHERE t.entreprise_id = ? ${statut ? 'AND t.est_publie = ?' : ''} ORDER BY t.created_at DESC, t.id DESC`,
    statut ? [req.user.id, statut === 'publie' ? 1 : 0] : [req.user.id]
  );
  res.json({ data: rows.map(fmtTest) });
});

// POST /api/entreprise/tests
router.post('/', validate(testSchema), async (req, res) => {
  const t = req.valid;
  const [r] = await db.execute(
    `INSERT INTO tests (entreprise_id, titre, description, duree_minutes, categorie, score_minimum, afficher_score)
     VALUES (?,?,?,?,?,?,?)`,
    [req.user.id, t.titre, t.description, t.dureeMinutes, t.categorie, t.scoreMinimum, t.afficherScore ? 1 : 0]
  );
  await logAction(req, { action: 'TEST_CREE', entite: 'test', entiteId: r.insertId });
  res.status(201).json(fmtTest(await getTest(req.user.id, r.insertId)));
});

// GET /api/entreprise/tests/:id
router.get('/:id', async (req, res) => res.json(fmtTest(await getTest(req.user.id, parseId(req.params.id)))));

// PUT /api/entreprise/tests/:id   (refusé si publié)
router.put('/:id', validate(testSchema), async (req, res) => {
  const test = await getTest(req.user.id, parseId(req.params.id));
  if (test.statut === 'publie') throw new AppError(409, 'Dépubliez le test avant de le modifier.');
  const t = req.valid;
  await db.execute(
    `UPDATE tests SET titre=?, description=?, duree_minutes=?, categorie=?, score_minimum=?, afficher_score=? WHERE id=?`,
    [t.titre, t.description, t.dureeMinutes, t.categorie, t.scoreMinimum, t.afficherScore ? 1 : 0, test.id]
  );
  await logAction(req, { action: 'TEST_MODIFIE', entite: 'test', entiteId: test.id });
  res.json(fmtTest(await getTest(req.user.id, test.id)));
});

// POST /api/entreprise/tests/:id/dupliquer
// Les questions de la banque sont partagées; les questions propres à l'entreprise sont COPIÉES.
router.post('/:id/dupliquer', async (req, res) => {
  const src = await getTest(req.user.id, parseId(req.params.id));
  const conn = await db.getConnection();
  let newId;
  try {
    await conn.beginTransaction();
    const [r] = await conn.execute(
      `INSERT INTO tests (entreprise_id, titre, description, duree_minutes, categorie, score_minimum, afficher_score, est_publie, duplique_de)
       VALUES (?,?,?,?,?,?,?, 0, ?)`,
      [src.entreprise_id, `${src.titre} (copie)`.slice(0, 200), src.description, src.duree_minutes, src.categorie, src.score_minimum, src.afficher_score, src.id]
    );
    newId = r.insertId;
    const [links] = await conn.query(
      `SELECT q.*, tq.position FROM test_questions tq JOIN v_questions q ON q.id = tq.question_id
       WHERE tq.test_id = ? ORDER BY tq.position`,
      [src.id]
    );
    for (const q of links) {
      let qid = q.id;
      if (q.entreprise_id !== null) {
        qid = await creerQuestion(conn, {
          entrepriseId: q.entreprise_id,
          enonce: q.enonce,
          optionA: q.option_a, optionB: q.option_b, optionC: q.option_c, optionD: q.option_d,
          reponseCorrecte: q.reponse_correcte,
          points: q.points,
        });
      }
      await conn.execute('INSERT INTO test_questions (test_id, question_id, position) VALUES (?,?,?)', [newId, qid, q.position]);
    }
    await conn.commit();
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
  await logAction(req, { action: 'TEST_DUPLIQUE', entite: 'test', entiteId: newId, details: { source: src.id } });
  res.status(201).json(fmtTest(await getTest(req.user.id, newId)));
});

// PATCH /api/entreprise/tests/:id/publier
router.patch('/:id/publier', async (req, res) => {
  const test = await getTest(req.user.id, parseId(req.params.id));
  if (Number(test.nb_questions) < 1) throw new AppError(409, 'Ajoutez au moins une question avant de publier.');
  if (Number(test.total_points) < 1) throw new AppError(409, 'Le total des points du test doit être supérieur à 0.');
  await db.execute(`UPDATE tests SET est_publie = 1 WHERE id = ?`, [test.id]);
  await logAction(req, { action: 'TEST_PUBLIE', entite: 'test', entiteId: test.id });
  res.json(fmtTest(await getTest(req.user.id, test.id)));
});

// PATCH /api/entreprise/tests/:id/depublier
router.patch('/:id/depublier', async (req, res) => {
  const test = await getTest(req.user.id, parseId(req.params.id));
  const [[r]] = await db.execute(`SELECT COUNT(*) AS n FROM invitations WHERE test_id = ? AND statut = 'en_cours'`, [test.id]);
  if (Number(r.n) > 0) throw new AppError(409, 'Des candidats ont un test en cours: dépublication impossible pour le moment.');
  await db.execute(`UPDATE tests SET est_publie = 0 WHERE id = ?`, [test.id]);
  await logAction(req, { action: 'TEST_DEPUBLIE', entite: 'test', entiteId: test.id });
  res.json(fmtTest(await getTest(req.user.id, test.id)));
});

module.exports = router;
