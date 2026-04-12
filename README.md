# Drop'In

Une app mobile pour ne plus chercher où jeter ses déchets. Drop'In permet de localiser les poubelles et points de collecte autour de soi, de signaler leur état, et d'en ajouter de nouvelles. Le tout de façon collaborative — chaque contribution améliore la carte pour tout le monde.

---

## Ce que ça fait

- Carte interactive avec les poubelles autour de toi (OpenStreetMap)
- Filtrer par type de déchet (verre, plastique, papier, bio...)
- Signaler une poubelle pleine ou vide — le statut se met à jour automatiquement après 3 signalements concordants
- Ajouter une nouvelle poubelle en un tap
- Système de points pour récompenser les contributions
- Compte utilisateur avec profil et historique

---

## Stack

**Backend**

| Couche | Techno |
|--------|--------|
| Langage | Rust (2021) |
| Framework web | Axum 0.7 |
| Base de données | PostgreSQL + PostGIS |
| Requêtes SQL | SQLx |
| Auth | JWT + Bcrypt |
| Runtime async | Tokio |

**Frontend**

| Couche | Techno |
|--------|--------|
| Framework | Flutter |
| Carte | flutter_map + OpenStreetMap |
| État | Riverpod |
| Navigation | go_router |
| HTTP | Dio |

---

## Lancer le projet en local

### Prérequis

- [Rust](https://rustup.rs/) stable
- [Flutter](https://flutter.dev) 3.x
- PostgreSQL avec l'extension PostGIS

La façon la plus simple de démarrer PostgreSQL + PostGIS sans l'installer :

```bash
docker run -d \
  --name dropin-db \
  -e POSTGRES_USER=user \
  -e POSTGRES_PASSWORD=password \
  -e POSTGRES_DB=dropin \
  -p 5432:5432 \
  postgis/postgis:16-3.4
```

### Backend

```bash
git clone https://github.com/Jonathan-p-z/Drop-In.git
cd Drop\'In
cp .env.example .env  # puis éditer avec tes valeurs
cargo run
```

Le serveur démarre sur `http://127.0.0.1:3000`. Les migrations SQL s'appliquent automatiquement au démarrage.

Variables d'environnement à configurer dans `.env` :

```env
DATABASE_URL=postgres://user:password@localhost:5432/dropin
JWT_SECRET=une-clé-secrète-longue-et-aléatoire
SERVER_HOST=127.0.0.1
SERVER_PORT=3000
JWT_EXPIRY_HOURS=24
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

Sur émulateur Android, l'app pointe vers `http://10.0.2.2:3000`. Sur Linux desktop, vers `http://127.0.0.1:3000`.

---

## API

### Publiques

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/health` | État du serveur |
| `POST` | `/api/auth/register` | Créer un compte |
| `POST` | `/api/auth/login` | Se connecter |
| `GET` | `/api/bins` | Lister les poubelles (filtrables par position, type, statut) |
| `GET` | `/api/bins/:id` | Détail d'une poubelle |

### Protégées (JWT requis)

| Méthode | Route | Description |
|---------|-------|-------------|
| `GET` | `/api/users/me` | Profil de l'utilisateur connecté |
| `POST` | `/api/bins` | Ajouter une poubelle |
| `POST` | `/api/bins/:id/report` | Signaler une poubelle |

---

## Structure

```
Drop'In/
├── src/
│   ├── main.rs
│   ├── config.rs
│   ├── db.rs
│   ├── errors.rs
│   ├── handlers/
│   │   ├── auth.rs          # Inscription, connexion
│   │   ├── users.rs         # Profil utilisateur
│   │   ├── bins.rs          # CRUD poubelles + recherche géographique
│   │   └── bin_reports.rs   # Signalements + réinitialisation automatique des statuts
│   ├── middleware/
│   │   └── auth.rs          # Validation JWT
│   ├── models/              # Structs partagés (DB + API)
│   └── routes/              # Définition des routes Axum
│
├── migrations/
│   ├── 001_extensions.sql   # UUID + PostGIS
│   ├── 002_users.sql
│   ├── 003_bins.sql         # Géométrie PostGIS (Point 4326)
│   ├── 004_bin_types.sql
│   └── 005_bin_reports.sql
│
└── frontend/
    └── lib/
        ├── core/            # Thème, couleurs, ApiService
        ├── features/
        │   ├── auth/        # Login, inscription, provider
        │   └── map/         # Carte, marqueurs, filtres, signalements
        └── shared/          # Widgets réutilisables
```

---

## Licence

[Prosperity Public License 3.0.0](./LICENSE) — usage non-commercial.
