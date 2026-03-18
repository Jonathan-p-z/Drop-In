use axum::{routing::get, Router};
use sqlx::PgPool;

use crate::handlers;

#[derive(Clone)]
pub struct AppState {
    // Etat partage volontairement petit; on garde le clone peu couteux.
    pub pool: PgPool,
    pub jwt_secret: String,
}

pub fn router(state: AppState) -> Router {
    // Table de routes minimale et lisible; les handlers font le gros du travail.
    Router::new()
        .route("/health", get(handlers::health))
        .route("/ws", get(handlers::ws_handler))
        .with_state(state)
}
