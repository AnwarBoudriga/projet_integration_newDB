const db = require('../config/db');

/**
 * Enregistre une action dans le journal d'activité.
 * N'interrompt jamais la requête en cas d'erreur.
 */
async function logAction(req, { action, entite = null, entiteId = null, details = null, acteurType, acteurId }) {
  try {
    await db.execute(
      `INSERT INTO audit_logs (acteur_type, acteur_id, action, entite, entite_id, details, ip)
       VALUES (?, ?, ?, ?, ?, ?, ?)`,
      [
        acteurType || req.user?.role || 'systeme',
        acteurId ?? req.user?.id ?? null,
        action,
        entite,
        entiteId,
        details ? JSON.stringify(details) : null,
        req.ip || null,
      ]
    );
  } catch (err) {
    console.error('[audit] échec:', err.message);
  }
}

module.exports = { logAction };
