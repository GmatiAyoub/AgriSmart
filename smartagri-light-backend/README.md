# SmartAgri Light: simulated irrigation API

Backend for a Flutter app. Valves are **simulated**: opening or closing only changes the
state stored in the database. There is no ESP32 and no MQTT. All the simulation lives in
`src/api/services/simulation.service.ts`, the only file to replace if real hardware comes later.

## Run it
1. Create an empty MySQL database and copy `.env.example` to `.env` (fill in the values).
2. `pnpm install`
3. `pnpm run seed`   (creates the tables, the single account and some demo data)
4. `pnpm run dev`

## Tables
`users`, `parcelles`, `vannes`, `planifications`.
A parcelle has many vannes and many planifications (both deleted with the parcelle).

## Authentication (login only, no registration)
`POST /api/auth/login` with `{ "username": "...", "password": "..." }` returns `{ token, user }`.
Send the token on every other request: `Authorization: Bearer <token>`.
Without a valid token, protected routes answer 401.

## Routes (all protected except login and health)
| Method | Route | Purpose |
|---|---|---|
| POST | /api/auth/login | Log in, returns the token |
| POST | /api/auth/logout | Clears the cookie (the app just forgets its token) |
| GET | /api/auth/me | Current user |
| GET | /api/health | Server check (public) |
| GET | /api/parcelles | List, each with `nombreVannes` and `irrigationActive` |
| GET | /api/parcelles/:id | One parcelle, with its `vannes` |
| POST | /api/parcelles | Create `{ nom, localisation?, notes? }` |
| PUT | /api/parcelles/:id | Edit |
| DELETE | /api/parcelles/:id | Delete (with its vannes and planifications) |
| POST | /api/parcelles/:id/irrigation | `{ "action": "ouvrir" | "fermer" }` opens or closes ALL its vannes |
| GET | /api/vannes?parcelleId= | List, optionally of one parcelle |
| GET | /api/vannes/:id | One vanne |
| POST | /api/vannes | Create `{ nom, parcelleId }` (starts closed) |
| PUT | /api/vannes/:id | Edit `{ nom }` |
| DELETE | /api/vannes/:id | Delete |
| POST | /api/vannes/:id/commande | `{ "action": "ouvrir" | "fermer" }` (valve and pump together) |
| GET | /api/planifications?parcelleId= | List, optionally of one parcelle |
| GET | /api/planifications/:id | One planification |
| POST | /api/planifications | Create (see below) |
| PUT | /api/planifications/:id | Edit |
| DELETE | /api/planifications/:id | Delete |

`irrigationActive` is true when at least one vanne of the parcelle is open. The app can show
"Fermer" when it is true and "Ouvrir" when it is false, without storing anything itself.

A vanne has `etat`: `"ouverte"` or `"fermee"`.

Planification body: `{ parcelleId, nom, heureDebut: "HH:mm", dureeMinutes: 1..1440,
joursSemaine: [0..6] (0 = dimanche), active?: true }`. At `heureDebut` on those days, all vannes
of the parcelle open, and they close after `dureeMinutes`. Two active planifications of the same
parcelle cannot overlap (409 `PLANIFICATION_CHEVAUCHEMENT`).

## Errors
Every error is `{ "message": "texte en français", "code": "CODE_STABLE" }`.
Main codes: VALIDATION, PARCELLE_INTROUVABLE, VANNE_INTROUVABLE, PLANIFICATION_INTROUVABLE,
AUCUNE_VANNE, PLANIFICATION_CHEVAUCHEMENT, IDENTIFIANTS_INVALIDES, AUTH_REQUISE, SESSION_INVALIDE.
