const router = require('express').Router();
const db = require('../../config/db');
const { requireAuth } = require('../../middlewares/auth');

router.use(requireAuth);

const one = async (sql) => (await db.query(sql))[0][0];

// GET /api/admin/stats
router.get('/', async (_req, res) => {
  const [ent, tests, candidats, questions, resultats] = await Promise.all([
    one(`SELECT COUNT(*) AS total, COALESCE(SUM(est_active),0) AS actives FROM entreprises`),
    one(`SELECT COUNT(*) AS total, COALESCE(SUM(est_publie),0) AS publies FROM tests`),
    one(`SELECT COUNT(*) AS total, COALESCE(SUM(statut='termine'),0) AS termines FROM invitations`),
    one(`SELECT COUNT(*) AS banque FROM questions WHERE entreprise_id IS NULL`),
    one(`SELECT COUNT(*) AS total, COALESCE(SUM(est_reussi),0) AS reussis, COALESCE(AVG(score/score_max*100),0) AS moyenne FROM passages WHERE date_soumission IS NOT NULL`),
  ]);

  const total = Number(resultats.total);
  res.json({
    entreprises: { total: Number(ent.total), actives: Number(ent.actives), inactives: Number(ent.total) - Number(ent.actives) },
    tests: { total: Number(tests.total), publies: Number(tests.publies) },
    candidats: { invites: Number(candidats.total), termines: Number(candidats.termines) },
    banqueQuestions: Number(questions.banque),
    resultats: {
      total,
      tauxReussite: total ? Math.round((Number(resultats.reussis) / total) * 1000) / 10 : 0,
      scoreMoyenPourcent: Math.round(Number(resultats.moyenne) * 10) / 10,
    },
  });
});

module.exports = router;
