const db = require('../config/db');

const LETTRES = ['A', 'B', 'C', 'D'];

/**
 * Une question = 1 ligne `questions` + 4 lignes `choix` (A-D, un seul est_correct).
 * `q` = objet validé par zod: { enonce, optionA..optionD, reponseCorrecte, points }.
 * En lecture, utiliser la vue `v_questions` (option_a..d + reponse_correcte).
 */

/** Crée la question et ses 4 choix. `conn` = connexion (dans une transaction). Retourne l'id. */
async function creerQuestion(conn, { entrepriseId = null, ...q }) {
  const source = entrepriseId == null ? 'BANQUE' : 'ENTREPRISE';
  const [r] = await conn.execute('INSERT INTO questions (entreprise_id, enonce, source, points) VALUES (?,?,?,?)', [
    entrepriseId,
    q.enonce,
    source,
    q.points,
  ]);
  for (const l of LETTRES) {
    await conn.execute('INSERT INTO choix (question_id, lettre, texte, est_correct) VALUES (?,?,?,?)', [
      r.insertId,
      l,
      q[`option${l}`],
      q.reponseCorrecte === l ? 1 : 0,
    ]);
  }
  return r.insertId;
}

/**
 * Modifie la question EN PLACE (les `choix` gardent leur id: les réponses déjà données restent valides).
 */
async function modifierQuestion(conn, id, q) {
  await conn.execute('UPDATE questions SET enonce = ?, points = ? WHERE id = ?', [q.enonce, q.points, id]);
  for (const l of LETTRES) {
    await conn.execute('UPDATE choix SET texte = ?, est_correct = ? WHERE question_id = ? AND lettre = ?', [
      q[`option${l}`],
      q.reponseCorrecte === l ? 1 : 0,
      id,
      l,
    ]);
  }
}

/** Exécute fn(conn) dans une transaction. */
async function enTransaction(fn) {
  const conn = await db.getConnection();
  try {
    await conn.beginTransaction();
    const out = await fn(conn);
    await conn.commit();
    return out;
  } catch (e) {
    await conn.rollback();
    throw e;
  } finally {
    conn.release();
  }
}

const creerQuestionTx = (params) => enTransaction((conn) => creerQuestion(conn, params));
const modifierQuestionTx = (id, q) => enTransaction((conn) => modifierQuestion(conn, id, q));

module.exports = { LETTRES, creerQuestion, modifierQuestion, enTransaction, creerQuestionTx, modifierQuestionTx };
