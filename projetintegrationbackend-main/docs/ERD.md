# Base de données PsyTech Pro (v3 — alignée sur le diagramme de classes)

```mermaid
erDiagram
  SUPER_ADMINS {
    int id PK
    string identifiant UK
    string nom
    string email UK
    string mot_de_passe_hash
  }
  ENTREPRISES {
    int id PK
    string nom
    string email UK
    string secteur
    char cle_hash UK
    bool est_active
    timestamp created_at "dateCreation"
  }
  TESTS {
    int id PK
    int entreprise_id FK
    string titre
    int duree_minutes
    string categorie
    int score_minimum
    bool afficher_score
    bool est_publie
    int duplique_de FK
  }
  QUESTIONS {
    int id PK
    int entreprise_id FK "NULL = banque"
    text enonce
    enum source "BANQUE | ENTREPRISE"
    int points
  }
  CHOIX {
    int id PK
    int question_id FK
    enum lettre "A-D"
    string texte
    bool est_correct
  }
  TEST_QUESTIONS {
    int test_id PK
    int question_id PK
    int position "ordre"
  }
  CANDIDATS {
    int id PK
    int entreprise_id FK
    string nom
    string email "UK avec entreprise_id"
  }
  INVITATIONS {
    int id PK
    int entreprise_id FK
    int test_id FK
    int candidat_id FK
    char cle_hash UK
    datetime expiration
    enum statut "invite | en_cours | termine | expire"
  }
  PASSAGES {
    int id PK
    int invitation_id FK,UK "0..1 par invitation"
    datetime date_debut
    datetime date_soumission
    int score
    int score_max
    bool est_reussi
  }
  REPONSES {
    int id PK
    int passage_id FK
    int question_id FK
    int choix_id FK
    bool est_correcte
  }
  AUDIT_LOGS {
    bigint id PK
    enum acteur_type
    string action
    json details
  }
  ENTREPRISES ||--o{ TESTS : possede
  ENTREPRISES ||--o{ QUESTIONS : ecrit
  ENTREPRISES ||--o{ CANDIDATS : "invite (par email)"
  ENTREPRISES ||--o{ INVITATIONS : genere
  CANDIDATS ||--o{ INVITATIONS : recoit
  TESTS ||--o{ TEST_QUESTIONS : contient
  QUESTIONS ||--o{ TEST_QUESTIONS : "utilisee dans"
  QUESTIONS ||--|{ CHOIX : "4 choix"
  TESTS ||--o{ INVITATIONS : "passe via"
  INVITATIONS ||--o| PASSAGES : "donne lieu a"
  PASSAGES ||--o{ REPONSES : contient
  QUESTIONS ||--o{ REPONSES : concerne
  CHOIX ||--o{ REPONSES : "choix selectionne"
```

## Correspondance diagramme de classes -> tables
| Classe | Table | Remarque |
|---|---|---|
| SuperAdmin | `super_admins` | `identifiant` sert au login |
| Entreprise | `entreprises` | `estActive` = `est_active`, `dateCreation` = `created_at` |
| Candidat | `candidats` | unique par (entreprise, email) |
| Invitation + `StatutInvitation` | `invitations` + ENUM `statut` | |
| Passage | `passages` | créé au démarrage du test; score/date_soumission remplis à la soumission |
| Test | `tests` | `estPublie` = `est_publie` |
| Question + `SourceQuestion` | `questions` + ENUM `source` | `entreprise_id` NULL <=> `BANQUE` |
| Choix | `choix` | 4 par question, 1 seul `est_correct` |
| TestQuestion | `test_questions` | `ordre` = `position` |
| Reponse | `reponses` | `est_correcte` copié depuis `choix.est_correct` |
| JournalActivite | `audit_logs` | |
| Statistiques / StatistiquesEntreprise | (pas de table) | calculées: `/admin/stats`, `v_dashboard_entreprise` |
| FormatExport | (pas de table) | enum du code (CSV / PDF) |

Vue `v_questions`: question + ses 4 choix "à plat" (`option_a..d`, `reponse_correcte`) — c'est elle que le code lit.

## Qui utilise quoi
| Module | Tables principales |
|---|---|
| Super Admin | `super_admins`, `entreprises`, `questions`/`choix` (source BANQUE), `audit_logs`, stats sur tout |
| Entreprise (RH) | `tests`, `questions`/`choix` (les siennes), `test_questions`, `candidats`, `invitations`, vues `v_tests_resume`, `v_resultats_detail`, `v_dashboard_entreprise` |
| Candidat | `invitations` (login par clé), `passages`, `reponses`, `v_questions` (sans la bonne réponse) |

## Requêtes utiles
**Questions d'un test, dans l'ordre** (sans la bonne réponse pour le candidat !):
```sql
SELECT q.id, q.enonce, q.option_a, q.option_b, q.option_c, q.option_d
FROM test_questions tq JOIN v_questions q ON q.id = tq.question_id
WHERE tq.test_id = ? ORDER BY tq.position;
```
**Enregistrer/changer une réponse** (le candidat peut revenir en arrière):
```sql
INSERT INTO reponses (passage_id, question_id, choix_id, est_correcte) VALUES (?, ?, ?, ?)
ON DUPLICATE KEY UPDATE choix_id = VALUES(choix_id), est_correcte = VALUES(est_correcte);
```
**Calcul du score à la soumission:**
```sql
SELECT COALESCE(SUM(CASE WHEN rp.est_correcte = 1 THEN q.points END), 0) AS score,
       COALESCE(SUM(q.points), 0) AS score_max
FROM test_questions tq
JOIN questions q ON q.id = tq.question_id
LEFT JOIN reponses rp ON rp.question_id = q.id AND rp.passage_id = ?
WHERE tq.test_id = ?;
```
**Login candidat** (clé valide, non expirée, entreprise active) — voir `INVITATION_SQL` dans `src/middlewares/auth.js`.
La clé reçue est hashée avec `hashKey()` de `src/utils/keys.js` avant la requête.
