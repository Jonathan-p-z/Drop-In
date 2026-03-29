# Drop'In

Drop'In, c'est une API backend pour une application de gestion collaborative des poubelles et points de collecte. L'idée : permettre aux gens de localiser, signaler et enrichir une carte communautaire de conteneurs de déchets — recyclage, organique, tout-venant — autour d'eux.

Le projet est en Rust avec Axum, tourne sur PostgreSQL avec PostGIS pour les requêtes géographiques, et utilise du JWT pour l'authentification.

---

## Ce que ça fait (pour l'instant)

- Inscription et connexion d'utilisateurs avec hashage bcrypt et tokens JWT
- Endpoint protégé pour récupérer le profil de l'utilisateur connecté
- Schéma de base de données prêt pour les poubelles (localisation GPS, type de déchet, statut, photo, vérification communautaire)
- Système de points pour gamifier les contributions
- WebSocket connecté (les handlers temps réel arrivent)
- Migrations auto au démarrage

---

## Stack

| Couche | Techno |
|--------|--------|
| Langage | Rust (2021) |
| Framework web | Axum 0.7 |
| Runtime async | Tokio |
| Base de données | PostgreSQL + PostGIS |
| ORM / queries | SQLx |
| Auth | JWT (`jsonwebtoken`) + Bcrypt |
| Sérialisation | Serde JSON |
| Logs | Tracing |

---

## Prérequis

- [Rust](https://rustup.rs/) (stable)
- PostgreSQL avec l'extension **PostGIS** installée
- Une base de données `dropin` créée

---

## Installation

```bash
git clone <url-du-repo>
cd Drop\'In
cp .env.example .env
```

Édite le `.env` avec tes valeurs :

```env
DATABASE_URL=postgres://user:password@localhost:5432/dropin
JWT_SECRET=une-clé-secrète-suffisamment-longue
SERVER_HOST=127.0.0.1
SERVER_PORT=3000
JWT_EXPIRY_HOURS=24    # optionnel, 24h par défaut
```

Lance le serveur :

```bash
cargo run
```

Les migrations sont appliquées automatiquement au démarrage. Le serveur écoute sur `http://127.0.0.1:3000` par défaut.

---

## Routes disponibles

### Publiques

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/health` | Vérifie que le serveur tourne |
| `GET` | `/ws` | Connexion WebSocket |
| `POST` | `/api/auth/register` | Créer un compte |
| `POST` | `/api/auth/login` | Se connecter |

### Protégées (Bearer token requis)

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/users/me` | Récupérer son profil |

---

## Exemples de requêtes

**Inscription**
```bash
curl -X POST http://localhost:3000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "alice",
    "email": "alice@example.com",
    "password": "motdepasse123"
  }'
```

**Connexion**
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "alice@example.com",
    "password": "motdepasse123"
  }'
```

Les deux endpoints retournent un token JWT et les infos de l'utilisateur.

**Profil**
```bash
curl http://localhost:3000/api/users/me \
  -H "Authorization: Bearer <ton_token>"
```

---

## Structure du projet

```
src/
├── main.rs            # Point d'entrée, démarrage du serveur
├── config.rs          # Lecture des variables d'environnement
├── db.rs              # Initialisation du pool de connexions et migrations
├── errors.rs          # Enum d'erreurs avec mapping HTTP
├── handlers/
│   ├── auth.rs        # Inscription et connexion
│   ├── users.rs       # Endpoints utilisateurs
│   └── mod.rs         # Health check et WebSocket
├── middleware/
│   └── auth.rs        # Validation JWT
├── models/            # Structs de données (BDD + requêtes/réponses)
└── routes/            # Définition des routes Axum

migrations/
├── 001_extensions.sql # UUID + PostGIS
├── 002_users.sql      # Table users
├── 003_bins.sql       # Table bins (avec géométrie PostGIS)
└── 004_bin_types.sql  # Table des types de déchets par poubelle
```

---

## Schéma de base de données

**`users`** — Les comptes utilisateurs. Contient un champ `points` pour suivre les contributions communautaires.

**`bins`** — Les poubelles. Stocke la position géographique en `GEOMETRY(Point, 4326)`, une photo optionnelle, une adresse, un statut et un flag `is_verified` pour la validation communautaire.

**`bin_types`** — Les types de déchets associés à chaque poubelle (recyclable, organique, tout-venant, etc.). Relation N-1 vers `bins`.

---

## Licence

[Prosperity Public License 3.0.0](./LICENSE) — usage non-commercial.
