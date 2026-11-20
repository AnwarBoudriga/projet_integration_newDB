// Calcule le score d'un passage (somme des points des réponses correctes: reponses.est_correcte).
async function calculerScore(conn, passageId, testId) {
  const [[r]] = await conn.query(
    `SELECT COALESCE(SUM(CASE WHEN rp.est_correcte = 1 THEN q.points END), 0) AS score,
            COALESCE(SUM(q.points), 0) AS score_max
     FROM test_questions tq
     JOIN questions q ON q.id = tq.question_id
     LEFT JOIN reponses rp ON rp.question_id = q.id AND rp.passage_id = ?
     WHERE tq.test_id = ?`,
    [passageId, testId]
  );
  return { score: Number(r.score), scoreMax: Number(r.score_max) };
}
module.exports = { calculerScore };
