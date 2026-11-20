// Test de bout en bout des 3 modules. Le serveur doit tourner:  npm run dev   puis   npm run test:api
require('dotenv').config();
const db = require('../src/config/db');

const BASE = process.env.API_URL || `http://localhost:${process.env.PORT || 3000}`;
let ok = 0;
let ko = 0;
const check = (nom, cond, extra = '') => {
  if (cond) { ok++; console.log('  OK     ', nom); } else { ko++; console.log('  ECHEC  ', nom, extra); }
};

async function call(method, path, { token, body, raw } = {}) {
  const res = await fetch(BASE + path, {
    method,
    headers: { ...(body ? { 'Content-Type': 'application/json' } : {}), ...(token ? { Authorization: `Bearer ${token}` } : {}) },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (raw) return res;
  let data = null;
  try { data = await res.json(); } catch { /* 204 */ }
  return { status: res.status, data };
}

const Q = (n, rep) => ({
  enonce: `Question ${n} : combien font ${n} + ${n} ?`,
  optionA: String(n), optionB: String(n * 2), optionC: String(n * 3), optionD: String(n * 4),
  reponseCorrecte: rep, points: 1,
});

(async () => {
  const sfx = Date.now();
  console.log(`\nAPI: ${BASE}\n\n== SUPER ADMIN`);
  let r = await call('POST', '/api/admin/auth/login', { body: { identifiant: process.env.ADMIN_IDENTIFIANT || 'superadmin', motDePasse: process.env.ADMIN_PASSWORD } });
  check('login admin', r.status === 200 && r.data.token, JSON.stringify(r.data));
  const admin = r.data.token;
  r = await call('POST', '/api/admin/entreprises', { token: admin, body: { nom: `Smoke Co ${sfx}`, email: `smoke${sfx}@test.tn`, secteur: 'Test' } });
  const entId = r.data.id;
  r = await call('POST', `/api/admin/entreprises/${entId}/cle`, { token: admin });
  const entKey = r.data.cle;
  check('entreprise créée + clé ENT-', /^ENT-/.test(entKey || ''));
  r = await call('POST', '/api/admin/questions', { token: admin, body: Q(7, 'C') });
  const bankId = r.data.id;
  check('question de banque créée', r.status === 201);

  console.log('\n== ENTREPRISE (RH)');
  r = await call('POST', '/api/entreprise/auth/login', { body: { cle: 'ENT-FAUX0000' } });
  check('mauvaise clé -> 401', r.status === 401);
  r = await call('POST', '/api/entreprise/auth/login', { body: { cle: entKey } });
  check('login par clé entreprise', r.status === 200 && r.data.token);
  const E = r.data.token;
  r = await call('GET', '/api/admin/entreprises', { token: E });
  check('token entreprise refusé sur routes admin -> 403', r.status === 403);

  r = await call('POST', '/api/entreprise/tests', { token: E, body: { titre: 'Test smoke', description: 'desc', dureeMinutes: 30, categorie: 'Logique', scoreMinimum: 50, afficherScore: true } });
  check('créer un test', r.status === 201 && r.data.statut === 'brouillon');
  const testId = r.data.id;
  r = await call('PATCH', `/api/entreprise/tests/${testId}/publier`, { token: E });
  check('publier sans question -> 409', r.status === 409);

  await call('POST', `/api/entreprise/tests/${testId}/questions`, { token: E, body: Q(2, 'A') });
  await call('POST', `/api/entreprise/tests/${testId}/questions`, { token: E, body: Q(3, 'B') });
  r = await call('POST', `/api/entreprise/tests/${testId}/questions/banque`, { token: E, body: { questionIds: [bankId] } });
  check('2 questions propres + 1 de la banque', r.status === 201 && r.data.data.length === 3);
  r = await call('GET', '/api/entreprise/banque', { token: E });
  check('liste de la banque', r.status === 200 && r.data.pagination.total >= 1);

  const q3 = r.data && (await call('GET', `/api/entreprise/tests/${testId}/questions`, { token: E })).data.data;
  const idsAvant = q3.map((q) => q.id);
  r = await call('POST', `/api/entreprise/tests/${testId}/questions/${idsAvant[2]}/monter`, { token: E });
  check('monter une question change l’ordre', r.data.data[1].id === idsAvant[2] && r.data.data[2].id === idsAvant[1]);
  const bankQ = r.data.data.find((q) => q.source === 'banque');
  r = await call('PUT', `/api/entreprise/tests/${testId}/questions/${bankQ.id}`, { token: E, body: Q(1, 'A') });
  check('modifier une question de la banque -> 403', r.status === 403);
  const own = r.status && (await call('GET', `/api/entreprise/tests/${testId}/questions`, { token: E })).data.data.find((q) => q.source === 'entreprise');
  r = await call('PUT', `/api/entreprise/tests/${testId}/questions/${own.id}`, { token: E, body: { ...Q(2, own.reponseCorrecte) } });
  check('modifier une question propre', r.status === 200);
  r = await call('POST', `/api/entreprise/tests/${testId}/questions`, { token: E, body: Q(9, 'D') });
  const tmp = r.data.data.find((q) => q.enonce.includes('9 + 9'));
  r = await call('DELETE', `/api/entreprise/tests/${testId}/questions/${tmp.id}`, { token: E });
  check('supprimer une question', r.status === 200 && r.data.data.length === 3);
  const correct = Object.fromEntries(r.data.data.map((q) => [q.id, q.reponseCorrecte]));
  const ordre = r.data.data.map((q) => q.id);

  r = await call('PATCH', `/api/entreprise/tests/${testId}/publier`, { token: E });
  check('publier le test', r.status === 200 && r.data.statut === 'publie' && r.data.nbQuestions === 3);
  r = await call('POST', `/api/entreprise/tests/${testId}/questions`, { token: E, body: Q(5, 'A') });
  check('modifier un test publié -> 409', r.status === 409);

  r = await call('POST', `/api/entreprise/tests/${testId}/dupliquer`, { token: E });
  check('dupliquer un test (brouillon, 3 questions)', r.status === 201 && r.data.statut === 'brouillon' && r.data.nbQuestions === 3 && r.data.dupliqueDe === testId);
  const dup = (await call('GET', `/api/entreprise/tests/${r.data.id}/questions`, { token: E })).data.data;
  check('copie: questions propres dupliquées, banque partagée', dup.filter((q) => q.source === 'entreprise').every((q) => !ordre.includes(q.id)) && dup.some((q) => q.id === bankId));

  r = await call('POST', '/api/entreprise/invitations', { token: E, body: { nom: 'Candidat Un', email: 'un@test.tn', testId: r.data.id, expirationJours: 7 } });
  check('inviter sur un test non publié -> 409', r.status === 409);
  r = await call('POST', '/api/entreprise/invitations', { token: E, body: { nom: 'Candidat Un', email: 'un@test.tn', testId, expirationJours: 7 } });
  check('créer une invitation (clé PSY-)', r.status === 201 && /^PSY-/.test(r.data.cle));
  const key1 = r.data.cle;
  const inv1 = r.data.id;
  const csv = 'nom;email\nAmine Ben Salah;amine@test.tn\nSarra Gharbi;sarra@test.tn\nSans Email;pas-un-email\nAmine Double;amine@test.tn\n';
  r = await call('POST', '/api/entreprise/invitations/import', { token: E, body: { testId, expirationJours: 3, csv } });
  check('import CSV: 2 créés, 2 erreurs', r.status === 201 && r.data.crees.length === 2 && r.data.erreurs.length === 2, JSON.stringify(r.data));
  const [c2, c3] = r.data.crees;
  r = await call('GET', '/api/entreprise/invitations', { token: E });
  check('liste "Candidats invités" (3)', r.data.data.length === 3 && r.data.pagination.total === 3);

  console.log('\n== CANDIDAT');
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: 'PSY-FAUX00' } });
  check('mauvaise clé -> 401', r.status === 401);
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: key1 } });
  check('login par clé candidat', r.status === 200 && r.data.statut === 'invite');
  const C = r.data.token;
  r = await call('GET', '/api/entreprise/tests', { token: C });
  check('token candidat refusé côté entreprise -> 403', r.status === 403);
  r = await call('GET', '/api/candidat/test', { token: C });
  check('infos du test (30 min, 3 questions)', r.data.dureeMinutes === 30 && r.data.nbQuestions === 3 && r.data.statut === 'invite');
  r = await call('PUT', `/api/candidat/test/reponses/${ordre[0]}`, { token: C, body: { choix: 'A' } });
  check('répondre avant de démarrer -> 409', r.status === 409);
  r = await call('POST', '/api/candidat/test/demarrer', { token: C });
  check('démarrer: 3 questions + chrono', r.status === 200 && r.data.questions.length === 3 && r.data.resteSecondes > 1700 && r.data.resteSecondes <= 1800);
  check('aucune bonne réponse envoyée au candidat', !JSON.stringify(r.data).includes('reponseCorrecte') && !JSON.stringify(r.data).includes('reponse_correcte'));
  // 2 bonnes réponses + 1 mauvaise
  const choix = { [ordre[0]]: correct[ordre[0]], [ordre[1]]: correct[ordre[1]], [ordre[2]]: correct[ordre[2]] === 'A' ? 'B' : 'A' };
  for (const [qid, c] of Object.entries(choix)) await call('PUT', `/api/candidat/test/reponses/${qid}`, { token: C, body: { choix: c } });
  r = await call('PUT', `/api/candidat/test/reponses/${ordre[2]}`, { token: C, body: { choix: 'A' } });
  check('changer une réponse (upsert), 3 répondues', r.status === 200 && r.data.repondues === 3);
  await call('PUT', `/api/candidat/test/reponses/${ordre[2]}`, { token: C, body: { choix: correct[ordre[2]] === 'A' ? 'B' : 'A' } });
  r = await call('GET', '/api/candidat/test/questions', { token: C });
  check('reprise: réponses déjà données restituées', Object.keys(r.data.reponses).length === 3 && r.data.repondues === 3);
  r = await call('POST', '/api/candidat/test/soumettre', { token: C });
  check('soumettre: score 2/3 visible', r.status === 200 && r.data.score === 2 && r.data.scoreMax === 3 && r.data.scoreVisible === true, JSON.stringify(r.data));
  r = await call('POST', '/api/candidat/test/soumettre', { token: C });
  check('soumettre 2 fois: idempotent', r.status === 200 && r.data.score === 2);
  r = await call('PUT', `/api/candidat/test/reponses/${ordre[0]}`, { token: C, body: { choix: 'D' } });
  check('répondre après soumission -> 409', r.status === 409);
  r = await call('GET', '/api/candidat/test/resultat', { token: C });
  check('consulter son score', r.status === 200 && r.data.score === 2);
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: key1 } });
  check('re-login après fin: statut termine', r.status === 200 && r.data.statut === 'termine');

  console.log('\n== CAS LIMITES (expiration, chrono)');
  await db.execute('UPDATE invitations SET expiration = DATE_SUB(NOW(), INTERVAL 1 DAY) WHERE id = ?', [c2.id]);
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: c2.cle } });
  check('invitation expirée -> 410', r.status === 410);
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: c3.cle } });
  const C3 = r.data.token;
  await call('POST', '/api/candidat/test/demarrer', { token: C3 });
  await call('PUT', `/api/candidat/test/reponses/${ordre[0]}`, { token: C3, body: { choix: correct[ordre[0]] } });
  await db.execute('UPDATE passages SET date_debut = DATE_SUB(NOW(), INTERVAL 31 MINUTE) WHERE invitation_id = ?', [c3.id]);
  r = await call('PUT', `/api/candidat/test/reponses/${ordre[1]}`, { token: C3, body: { choix: 'A' } });
  check('temps écoulé -> 409 + soumission automatique', r.status === 409 && /Temps écoulé/.test(r.data.message));
  r = await call('GET', '/api/candidat/test/resultat', { token: C3 });
  check('résultat auto: 1/3 (réponse donnée avant la fin)', r.status === 200 && r.data.score === 1 && r.data.scoreMax === 3, JSON.stringify(r.data));

  console.log('\n== ENTREPRISE: tableau de bord et résultats');
  r = await call('GET', '/api/entreprise/dashboard', { token: E });
  check('dashboard: 2 tests, 3 candidats, taux de réussite', r.data.tests === 2 && r.data.candidats === 3 && r.data.tauxReussite === 50, JSON.stringify(r.data));
  r = await call('GET', '/api/entreprise/resultats', { token: E });
  check('liste des résultats (2)', r.data.data.length === 2);
  r = await call('GET', `/api/entreprise/resultats/${inv1}`, { token: E });
  check('résultat détaillé: 2/3, 66.7 %, réussi, 3 réponses', r.data.score === 2 && r.data.pourcentage === 66.7 && r.data.reussi === true && r.data.questions.length === 3 && r.data.questions.filter((q) => q.correcte).length === 2, JSON.stringify(r.data).slice(0, 200));
  let raw = await call('GET', `/api/entreprise/resultats/${inv1}/export.csv`, { token: E, raw: true });
  let txt = await raw.text();
  check('export CSV (candidat)', raw.status === 200 && /text\/csv/.test(raw.headers.get('content-type')) && txt.includes('Candidat Un') && txt.includes('2 / 3'));
  raw = await call('GET', `/api/entreprise/resultats/${inv1}/export.pdf`, { token: E, raw: true });
  const buf = Buffer.from(await raw.arrayBuffer());
  check('export PDF (candidat)', raw.status === 200 && buf.slice(0, 4).toString() === '%PDF' && buf.length > 1000, `taille=${buf.length}`);
  raw = await call('GET', '/api/entreprise/resultats/export.csv', { token: E, raw: true });
  txt = await raw.text();
  check('export CSV (tous les résultats)', raw.status === 200 && txt.split('\n').length >= 3);
  r = await call('GET', '/api/entreprise/invitations?statut=termine', { token: E });
  check('filtre invitations par statut', r.data.data.length === 2);

  console.log('\n== DÉSACTIVATION par le Super Admin');
  await call('PATCH', `/api/admin/entreprises/${entId}/desactiver`, { token: admin });
  r = await call('GET', '/api/entreprise/tests', { token: E });
  check('token entreprise coupé immédiatement -> 403', r.status === 403);
  r = await call('POST', '/api/entreprise/auth/login', { body: { cle: entKey } });
  check('login entreprise désactivée -> 403', r.status === 403);
  r = await call('POST', '/api/candidat/auth/login', { body: { cle: key1 } });
  check('login candidat d’une entreprise désactivée -> 403', r.status === 403);
  await call('PATCH', `/api/admin/entreprises/${entId}/activer`, { token: admin });
  r = await call('GET', '/api/admin/logs?limit=200', { token: admin });
  const actions = new Set(r.data.data.map((l) => l.action));
  check('journal: actions des 3 profils tracées', ['ENTREPRISE_LOGIN', 'TEST_PUBLIE', 'INVITATION_CREEE', 'CANDIDAT_LOGIN', 'TEST_SOUMIS'].every((a) => actions.has(a)), [...actions].join(','));

  console.log(`\nRésultat: ${ok} OK, ${ko} échec(s)\n`);
  await db.end();
  process.exit(ko ? 1 : 0);
})().catch(async (e) => {
  console.error(e);
  await db.end();
  process.exit(1);
});
