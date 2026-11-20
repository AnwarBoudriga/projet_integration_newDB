const router = require('express').Router();
const { requireEntreprise } = require('../../middlewares/auth');
const questions = require('./questions');

router.use('/auth', require('./auth')); // login public

// Tout le reste nécessite un token Entreprise valide ET une entreprise active
router.use(requireEntreprise);
router.use('/dashboard', require('./dashboard'));
router.use('/tests/:testId/questions', questions.testQuestions);
router.use('/tests', require('./tests'));
router.use('/banque', questions.banque);
router.use('/invitations', require('./invitations'));
router.use('/resultats', require('./resultats'));

module.exports = router;
