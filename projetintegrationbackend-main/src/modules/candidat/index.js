const router = require('express').Router();

router.use('/auth', require('./auth'));
router.use('/test', require('./test'));

module.exports = router;
