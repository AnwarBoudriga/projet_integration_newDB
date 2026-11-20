const app = require('./app');
const db = require('./config/db');

const PORT = process.env.PORT || 3000;

(async () => {
  try {
    await db.query('SELECT 1');
    console.log('MySQL connecté.');
  } catch (e) {
    console.error('Connexion MySQL impossible:', e.message);
    process.exit(1);
  }
  const server = app.listen(PORT, () => console.log(`API PsyTech Pro sur http://localhost:${PORT}`));

  // Arrêt propre (Ctrl+C / déploiement): on ferme le serveur puis le pool MySQL.
  const stop = () => server.close(() => db.end().then(() => process.exit(0)));
  process.on('SIGINT', stop);
  process.on('SIGTERM', stop);
})();
