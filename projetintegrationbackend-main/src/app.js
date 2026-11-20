require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const { notFound, errorHandler } = require('./middlewares/error');
const db = require('./config/db');

const app = express();

app.disable('x-powered-by');
app.set('trust proxy', 1);
app.use(helmet());
app.use(cors({ origin: !process.env.CORS_ORIGIN || process.env.CORS_ORIGIN === '*' ? true : process.env.CORS_ORIGIN.split(',') }));
app.use(express.json({ limit: '3mb' })); // import CSV

// Anti brute-force sur les 3 logins (une limite par profil)
const loginLimiter = () =>
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: Number(process.env.LOGIN_RATE_LIMIT || 10),
    message: { message: 'Trop de tentatives, réessayez plus tard.' },
  });
app.use('/api/admin/auth/login', loginLimiter());
app.use('/api/entreprise/auth/login', loginLimiter());
app.use('/api/candidat/auth/login', loginLimiter());

app.get('/api/health', async (_req, res) => {
  try {
    await db.query('SELECT 1');
    res.json({ status: 'ok', db: 'ok' });
  } catch {
    res.status(503).json({ status: 'error', db: 'down' });
  }
});

app.use('/api/admin', require('./modules/admin'));
app.use('/api/entreprise', require('./modules/entreprise'));
app.use('/api/candidat', require('./modules/candidat'));

app.use(notFound);
app.use(errorHandler);

module.exports = app;
