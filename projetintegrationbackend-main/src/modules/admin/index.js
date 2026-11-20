const router = require('express').Router();

router.use('/auth', require('./auth'));
router.use('/entreprises', require('./entreprises'));
router.use('/questions', require('./questions'));
router.use('/stats', require('./stats'));
router.use('/logs', require('./logs'));

module.exports = router;
