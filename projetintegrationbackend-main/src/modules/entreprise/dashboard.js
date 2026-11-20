const router = require('express').Router();
const db = require('../../config/db');

// GET /api/entreprise/dashboard  -> { tests, candidats, tauxReussite }
router.get('/', async (req, res) => {
  const [[r]] = await db.execute(
    'SELECT nb_tests, nb_candidats, taux_reussite FROM v_dashboard_entreprise WHERE entreprise_id = ?',
    [req.user.id]
  );
  res.json({
    tests: Number(r.nb_tests),
    candidats: Number(r.nb_candidats),
    tauxReussite: r.taux_reussite == null ? null : Number(r.taux_reussite),
  });
});

module.exports = router;
