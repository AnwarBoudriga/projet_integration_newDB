# PsyTech Pro — Backend (Super Admin + Entreprise + Candidat)

API Node.js / Express / MySQL (base `psytech_pro`, visible dans phpMyAdmin).

> **Projet unifié**: un seul backend, une seule base MySQL `psytech_pro` pour les 3 acteurs.
> Le module Entreprise de l'ancien backend PostgreSQL (`/backend`, auth seulement) est inclus ici
> (`/api/entreprise/*`, complet), donc plus besoin de PostgreSQL. Collection Postman: `docs/PsyTech.postman_collection.json`.

## Installation (Windows + XAMPP)
1. XAMPP: **Start** sur MySQL.
2. phpMyAdmin: supprimer l'ancienne base (`psytech` ou `psytech_pro`) si elle existe, puis **Importer** `database/schema.sql`
   (v3: le schéma a changé, il faut réimporter; les anciennes données de test sont perdues).
3. Dans ce dossier:
```powershell
copy .env.example .env        # puis éditer .env (JWT_SECRET, KEY_SECRET, ADMIN_PASSWORD; optionnel: ADMIN_NOM, ADMIN_EMAIL)
npm.cmd install
npm.cmd run seed:admin        # crée le Super Admin
npm.cmd run seed:demo:reset   # (optionnel) données de démo + affiche les clés ENT-/PSY-
npm.cmd run dev               # http://localhost:3000
npm.cmd run test:api          # (optionnel) test de bout en bout: 50 vérifications
```
`DB_USER=root` et `DB_PASSWORD=` (vide) conviennent à XAMPP par défaut.

## Structure (1 dossier par membre de l'équipe)
```
src/
├── app.js                 monte les 3 modules
├── config/db.js           connexion MySQL (partagée)
├── middlewares/           auth (JWT par profil), validate, erreurs
├── utils/                 keys (hash des clés), audit, score, mailer, csv
└── modules/
    ├── admin/             Super Administrateur
    ├── entreprise/        Entreprise (RH)
    └── candidat/          Candidat
```

## Authentification
| Profil | Login | Token (`Authorization: Bearer ...`) |
|---|---|---|
| Super Admin | `POST /api/admin/auth/login` `{identifiant, motDePasse}` | role `super_admin` |
| Entreprise | `POST /api/entreprise/auth/login` `{cle:"ENT-XXXXXXXX"}` | role `entreprise` |
| Candidat | `POST /api/candidat/auth/login` `{cle:"PSY-XXXXXX"}` | role `candidat` |

Un token d'un profil est refusé (403) sur les routes d'un autre profil. Le token Entreprise est revérifié à
chaque requête: si le Super Admin désactive l'entreprise, l'accès est coupé immédiatement (RH et candidats).

## Endpoints — Super Admin (`/api/admin`)
| Méthode | Route | Description |
|---|---|---|
| GET | /entreprises?search=&statut=&page=&limit= | Lister / rechercher / filtrer |
| POST | /entreprises | Créer `{nom,email,secteur}` |
| PATCH | /entreprises/:id/activer · /desactiver | Activer / désactiver |
| POST | /entreprises/:id/cle · /cle/regenerer | Générer / régénérer la clé `ENT-XXXXXXXX` |
| GET | /stats | Statistiques globales |
| GET | /logs?action=&acteurType=&from=&to= | Journal d'activité |
| GET/POST/PUT/DELETE | /questions[/:id] | Banque de questions |

## Endpoints — Entreprise (`/api/entreprise`)
| Méthode | Route | Description |
|---|---|---|
| GET | /dashboard | `{tests, candidats, tauxReussite}` |
| GET/POST | /tests | Lister / créer `{titre,description,dureeMinutes,categorie,scoreMinimum,afficherScore}` |
| GET/PUT | /tests/:id | Détail / modifier (refusé si publié) |
| POST | /tests/:id/dupliquer | Dupliquer (copie en brouillon) |
| PATCH | /tests/:id/publier · /depublier | Publier / dépublier |
| GET | /tests/:id/questions | Questions du test (dans l'ordre) |
| POST | /tests/:id/questions | Ajouter une question `{enonce,optionA..D,reponseCorrecte,points}` |
| POST | /tests/:id/questions/banque | Utiliser la banque `{questionIds:[..]}` |
| PUT / DELETE | /tests/:id/questions/:qid | Modifier / retirer |
| POST | /tests/:id/questions/:qid/monter · /descendre | Réordonner |
| GET | /banque?search= | Questions du Super Admin |
| POST | /invitations | Clé candidat `{nom,email,testId,expirationJours}` |
| POST | /invitations/import | Import CSV `{testId,expirationJours,csv:"nom;email\n..."}` |
| GET | /invitations?testId=&statut=&search= | Candidats invités + statut |
| DELETE | /invitations/:id | Supprimer (si pas commencé) |
| GET | /resultats?testId=&search= | Candidats ayant un résultat |
| GET | /resultats/:invitationId | Résultat détaillé par question |
| GET | /resultats/:invitationId/export.csv · export.pdf | Export |
| GET | /resultats/export.csv | Export de tous les résultats |

`scoreMinimum` est un **pourcentage (0-100)**: le candidat réussit si `score / total des points × 100 >= scoreMinimum`.

Règle: un test publié (ou déjà commencé par un candidat) n'est plus modifiable → dépublier ou dupliquer.

## Endpoints — Candidat (`/api/candidat`)
| Méthode | Route | Description |
|---|---|---|
| GET | /test | Infos: titre, durée, nombre de questions, statut |
| POST | /test/demarrer | Lance le chronomètre (une seule fois), renvoie questions + temps restant |
| GET | /test/questions | Reprise après rafraîchissement |
| PUT | /test/reponses/:questionId `{choix:"A"}` | Répondre / changer sa réponse |
| POST | /test/soumettre | Correction + email de confirmation |
| GET | /test/resultat | Score (seulement si `afficherScore`) |

Le chronomètre est géré côté serveur (`resteSecondes`): à la fin du temps, le test est soumis automatiquement.
Les bonnes réponses ne sont jamais envoyées au candidat.

## Emails
Sans `SMTP_HOST` dans `.env`, les emails (invitation avec la clé, confirmation de soumission) sont **affichés
dans la console du serveur**. Pour de vrais envois: Gmail (mot de passe d'application), Brevo, Mailtrap...

## Base de données
Voir `database/schema.sql` et `docs/ERD.md` (alignés sur le diagramme de classes: `candidats`, `invitations`, `passages`,
`reponses`, `questions` + `choix`, ...). `npm run seed:demo:reset` **efface** les données (sauf Super Admin).

## Règles d'équipe
- `.env` ne va jamais sur GitHub; `JWT_SECRET` et `KEY_SECRET` identiques chez les 3 membres.
- Chacun travaille dans son dossier `src/modules/<profil>/`. Fichiers partagés: `app.js`, `middlewares/`, `utils/`, `schema.sql`.
