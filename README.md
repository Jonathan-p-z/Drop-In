# dropin-backend

Rust backend skeleton using Axum, Tokio, SQLx (Postgres/PostGIS), and JWT authentication.

## Quick start

1. Copy `.env.example` to `.env` and fill values.
2. Run `cargo run`.

## Notes

- SQLx is wired for PostgreSQL; ensure PostGIS is enabled in your database.
- WebSocket support is enabled via Axum.
