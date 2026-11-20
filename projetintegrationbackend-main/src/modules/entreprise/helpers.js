const db = require('../../config/db');
const AppError = require('../../utils/AppError');

const parseId = (v, label = 'Identifiant') => {
  const id = Number(v);
  if (!Number.isInteger(id) || id < 1) throw new AppError(400, `${label} invalide.`);
  return id;
};

const TEST_SELECT = `
  SELECT t.*, CASE WHEN t.est_publie = 1 THEN 'publie' ELSE 'brouillon' END AS statut,
    (SELECT COUNT(*) FROM test_questions tq WHERE tq.test_id = t.id) AS nb_questions,
    (SELECT COALESCE(SUM(q.points), 0) FROM test_questions tq JOIN questions q ON q.id = tq.question_id
      WHERE tq.test_id = t.id) AS total_points
  FROM tests t`;

const fmtTest = (r) => ({
  id: r.id,
  titre: r.titre,
  description: r.description,
  dureeMinutes: r.duree_minutes,
  categorie: r.categorie,
  scoreMinimum: r.score_minimum,
  afficherScore: Boolean(r.afficher_score),
  statut: r.statut,
  nbQuestions: Number(r.nb_questions),
  totalPoints: Number(r.total_points),
  dupliqueDe: r.duplique_de,
  createdAt: r.created_at,
});

/** Retourne le test s'il appartient à l'entreprise, sinon 404. */
async function getTest(entrepriseId, id) {
  const [rows] = await db.execute(`${TEST_SELECT} WHERE t.id = ? AND t.entreprise_id = ?`, [id, entrepriseId]);
  if (!rows[0]) throw new AppError(404, 'Test introuvable.');
  return rows[0];
}

/** Un test publié ou déjà commencé par des candidats ne doit plus changer. */
async function assertEditable(test) {
  if (test.statut === 'publie') throw new AppError(409, 'Dépubliez le test avant de le modifier.');
  const [[r]] = await db.execute(
    `SELECT COUNT(*) AS n FROM invitations WHERE test_id = ? AND statut IN ('en_cours','termine')`,
    [test.id]
  );
  if (Number(r.n) > 0) {
    throw new AppError(409, 'Des candidats ont déjà commencé ce test: modification impossible. Dupliquez-le pour créer une nouvelle version.');
  }
}

module.exports = { parseId, TEST_SELECT, fmtTest, getTest, assertEditable };
