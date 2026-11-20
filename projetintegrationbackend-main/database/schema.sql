-- =====================================================================
--  PsyTech Pro — Base de données COMMUNE (Super Admin / Entreprise / Candidat)
--  v3 — alignée sur le diagramme de classes (Candidat, Passage, Choix, Reponse, ...).
--  Pour repartir de zéro (données de test seulement):
--      DROP DATABASE psytech_pro;   puis réimporter ce fichier.
--
--  Correspondance classe -> table:
--    SuperAdmin -> super_admins        Entreprise    -> entreprises
--    Test       -> tests               Question      -> questions (+ enum source)
--    Choix      -> choix               TestQuestion  -> test_questions (ordre = position)
--    Candidat   -> candidats           Invitation    -> invitations
--    Passage    -> passages            Reponse       -> reponses
--    JournalActivite -> audit_logs     Statistiques  -> calculées (vues / requêtes)
-- =====================================================================
CREATE DATABASE IF NOT EXISTS psytech_pro CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE psytech_pro;

-- ---------------------------------------------------------------------
-- SUPER ADMIN
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS super_admins (
  id INT AUTO_INCREMENT PRIMARY KEY,
  identifiant VARCHAR(50) NOT NULL UNIQUE,            -- login
  nom VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  mot_de_passe_hash VARCHAR(255) NOT NULL,            -- bcrypt
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS entreprises (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  secteur VARCHAR(100) DEFAULT '',
  cle_hash CHAR(64) NULL UNIQUE,                      -- HMAC-SHA256 de ENT-XXXXXXXX
  est_active TINYINT(1) NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- dateCreation
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_ent_active (est_active)
);

-- ---------------------------------------------------------------------
-- ENTREPRISE (RH): tests + questions
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS tests (
  id INT AUTO_INCREMENT PRIMARY KEY,
  entreprise_id INT NOT NULL,
  titre VARCHAR(200) NOT NULL,
  description TEXT,
  duree_minutes INT NOT NULL,
  categorie VARCHAR(100),
  score_minimum INT NOT NULL DEFAULT 0,               -- score minimum de réussite
  afficher_score TINYINT(1) NOT NULL DEFAULT 0,       -- afficherScoreCandidat
  est_publie TINYINT(1) NOT NULL DEFAULT 0,
  duplique_de INT NULL,                               -- si créé par "Dupliquer"
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CHECK (duree_minutes > 0),
  CHECK (score_minimum >= 0),
  INDEX idx_tests_ent (entreprise_id, est_publie),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(id) ON DELETE CASCADE,
  FOREIGN KEY (duplique_de) REFERENCES tests(id) ON DELETE SET NULL
);

-- source = 'BANQUE'     <=> entreprise_id NULL (créée par le Super Admin)
-- source = 'ENTREPRISE' <=> entreprise_id renseigné (écrite par une entreprise)
-- (cohérence garantie par src/utils/questions.js)
CREATE TABLE IF NOT EXISTS questions (
  id INT AUTO_INCREMENT PRIMARY KEY,
  entreprise_id INT NULL,
  enonce TEXT NOT NULL,
  source ENUM('BANQUE','ENTREPRISE') NOT NULL,
  points INT NOT NULL DEFAULT 1,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CHECK (points > 0),
  INDEX idx_q_ent (entreprise_id),
  INDEX idx_q_source (source),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(id) ON DELETE CASCADE
);

-- Chaque question a 4 choix (A-D), dont un seul est correct (composition Question -> Choix)
CREATE TABLE IF NOT EXISTS choix (
  id INT AUTO_INCREMENT PRIMARY KEY,
  question_id INT NOT NULL,
  lettre ENUM('A','B','C','D') NOT NULL,
  texte VARCHAR(255) NOT NULL,
  est_correct TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_choix (question_id, lettre),
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE
);

-- Classe d'association TestQuestion: ordre = position -> réordonner = UPDATE position
CREATE TABLE IF NOT EXISTS test_questions (
  test_id INT NOT NULL,
  question_id INT NOT NULL,
  position INT NOT NULL DEFAULT 0,
  PRIMARY KEY (test_id, question_id),
  INDEX idx_tq_pos (test_id, position),
  FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE RESTRICT
);

-- ---------------------------------------------------------------------
-- CANDIDAT (une personne invitée par une entreprise, identifiée par son email)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS candidats (
  id INT AUTO_INCREMENT PRIMARY KEY,
  entreprise_id INT NOT NULL,                         -- chaque entreprise ne voit que ses candidats
  nom VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uq_candidat_ent_email (entreprise_id, email),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- ENTREPRISE -> CANDIDAT: invitations (1 candidat reçoit * invitations)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS invitations (
  id INT AUTO_INCREMENT PRIMARY KEY,
  entreprise_id INT NOT NULL,
  test_id INT NOT NULL,
  candidat_id INT NOT NULL,
  cle_hash CHAR(64) NOT NULL UNIQUE,                  -- HMAC-SHA256 de PSY-XXXXXX
  expiration DATETIME NOT NULL,                       -- dateExpiration
  statut ENUM('invite','en_cours','termine','expire') NOT NULL DEFAULT 'invite',
  email_envoye_at DATETIME NULL,                      -- confirmation par email
  lot_import VARCHAR(40) NULL,                        -- identifiant d'un import CSV
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- dateGeneration
  INDEX idx_inv_ent (entreprise_id, statut),
  INDEX idx_inv_test (test_id),
  INDEX idx_inv_cand (candidat_id),
  INDEX idx_inv_exp (expiration),
  FOREIGN KEY (entreprise_id) REFERENCES entreprises(id) ON DELETE CASCADE,
  FOREIGN KEY (test_id) REFERENCES tests(id) ON DELETE CASCADE,
  FOREIGN KEY (candidat_id) REFERENCES candidats(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- PASSAGE (une invitation donne lieu à 0..1 passage) + RÉPONSES
-- date_soumission / score / score_max / est_reussi restent NULL tant que le test n'est pas soumis.
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS passages (
  id INT AUTO_INCREMENT PRIMARY KEY,
  invitation_id INT NOT NULL UNIQUE,                  -- 0..1 par invitation
  date_debut DATETIME NOT NULL,                       -- démarre le chronomètre
  date_soumission DATETIME NULL,
  score INT NULL,
  score_max INT NULL,
  est_reussi TINYINT(1) NULL,
  FOREIGN KEY (invitation_id) REFERENCES invitations(id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS reponses (
  id INT AUTO_INCREMENT PRIMARY KEY,
  passage_id INT NOT NULL,
  question_id INT NOT NULL,
  choix_id INT NOT NULL,                              -- le choix sélectionné
  est_correcte TINYINT(1) NOT NULL DEFAULT 0,
  UNIQUE KEY uq_rep (passage_id, question_id),        -- une seule réponse par question
  FOREIGN KEY (passage_id) REFERENCES passages(id) ON DELETE CASCADE,
  FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE,
  FOREIGN KEY (choix_id) REFERENCES choix(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------
-- JOURNAL D'ACTIVITÉ (audit)
-- ---------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS audit_logs (
  id BIGINT AUTO_INCREMENT PRIMARY KEY,
  acteur_type ENUM('super_admin','entreprise','candidat','systeme') NOT NULL,
  acteur_id INT NULL,
  action VARCHAR(100) NOT NULL,
  entite VARCHAR(50) NULL,
  entite_id INT NULL,
  details JSON NULL,
  ip VARCHAR(45) NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_action (action),
  INDEX idx_created (created_at),
  INDEX idx_acteur (acteur_type, acteur_id)
);

-- ---------------------------------------------------------------------
-- VUES pratiques (lecture seule)
-- ---------------------------------------------------------------------
-- Question + ses 4 choix "à plat" (option_a..d, reponse_correcte): utilisée par tout le code en lecture
CREATE OR REPLACE VIEW v_questions AS
SELECT q.id, q.entreprise_id, q.enonce, q.source, q.points, q.created_at,
       MAX(CASE WHEN c.lettre = 'A' THEN c.texte END) AS option_a,
       MAX(CASE WHEN c.lettre = 'B' THEN c.texte END) AS option_b,
       MAX(CASE WHEN c.lettre = 'C' THEN c.texte END) AS option_c,
       MAX(CASE WHEN c.lettre = 'D' THEN c.texte END) AS option_d,
       MAX(CASE WHEN c.est_correct = 1 THEN c.lettre END) AS reponse_correcte
FROM questions q
LEFT JOIN choix c ON c.question_id = q.id
GROUP BY q.id, q.entreprise_id, q.enonce, q.source, q.points, q.created_at;

-- Entreprise: liste des tests avec nombre de questions et total de points
CREATE OR REPLACE VIEW v_tests_resume AS
SELECT t.id, t.entreprise_id, t.titre, t.categorie, t.est_publie, t.duree_minutes,
       t.score_minimum, t.afficher_score,
       COUNT(tq.question_id)  AS nb_questions,
       COALESCE(SUM(q.points), 0) AS total_points
FROM tests t
LEFT JOIN test_questions tq ON tq.test_id = t.id
LEFT JOIN questions q ON q.id = tq.question_id
GROUP BY t.id;

-- Entreprise: résultats détaillés par candidat (écran "Résultats" + export CSV/PDF)
-- = passages soumis
CREATE OR REPLACE VIEW v_resultats_detail AS
SELECT p.id AS resultat_id, i.entreprise_id, i.id AS invitation_id,
       c.nom AS candidat_nom, c.email AS candidat_email,
       t.id AS test_id, t.titre AS test_titre,
       p.score, p.score_max,
       ROUND(p.score / p.score_max * 100, 1) AS pourcentage,
       p.est_reussi AS reussi,
       TIMESTAMPDIFF(SECOND, p.date_debut, p.date_soumission) AS duree_secondes,
       p.date_soumission AS soumis_at
FROM passages p
JOIN invitations i ON i.id = p.invitation_id
JOIN candidats c ON c.id = i.candidat_id
JOIN tests t ON t.id = i.test_id
WHERE p.date_soumission IS NOT NULL;

-- Entreprise: tableau de bord (tests, candidats, taux de réussite)
CREATE OR REPLACE VIEW v_dashboard_entreprise AS
SELECT e.id AS entreprise_id,
       (SELECT COUNT(*) FROM tests t WHERE t.entreprise_id = e.id) AS nb_tests,
       (SELECT COUNT(*) FROM invitations i WHERE i.entreprise_id = e.id) AS nb_candidats,
       (SELECT ROUND(100 * AVG(p.est_reussi), 1)
          FROM passages p JOIN invitations i ON i.id = p.invitation_id
         WHERE i.entreprise_id = e.id AND p.date_soumission IS NOT NULL) AS taux_reussite
FROM entreprises e;
