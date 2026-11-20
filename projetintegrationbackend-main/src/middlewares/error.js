const { ZodError } = require('zod');
const AppError = require('../utils/AppError');

function notFound(_req, res) {
  res.status(404).json({ message: 'Route introuvable.' });
}

// eslint-disable-next-line no-unused-vars
function errorHandler(err, _req, res, _next) {
  if (err instanceof ZodError) {
    return res.status(400).json({
      message: 'Données invalides.',
      errors: err.issues.map((i) => ({ champ: i.path.join('.'), message: i.message })),
    });
  }
  if (err instanceof AppError) return res.status(err.status).json({ message: err.message });
  if (err.code === 'ER_DUP_ENTRY') return res.status(409).json({ message: 'Cette valeur existe déjà.' });
  if (err.code === 'ER_ROW_IS_REFERENCED_2') {
    return res.status(409).json({ message: "Suppression impossible: l'élément est utilisé ailleurs." });
  }
  console.error(err);
  res.status(500).json({ message: 'Erreur interne du serveur.' });
}

module.exports = { notFound, errorHandler };
