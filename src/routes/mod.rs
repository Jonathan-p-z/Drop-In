use axum::{
    middleware,
    routing::{get, post},
    Router,
};
use sqlx::PgPool;
use tower_http::{cors::CorsLayer, trace::TraceLayer};

use crate::handlers;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub jwt_secret: String,
    pub jwt_expiry_hours: u64,
}

pub fn router(state: AppState) -> Router {
    let protected = Router::new()
        .route("/api/users/me", get(handlers::users::me))
        .route("/api/bins", post(handlers::bins::create_bin))
        .route("/api/bins/:id/report", post(handlers::bin_reports::report_bin))
        .route_layer(middleware::from_fn_with_state(
            state.clone(),
            crate::middleware::auth::require_auth,
        ));

    Router::new()
        .route("/health", get(handlers::health))
        .route("/ws", get(handlers::ws_handler))
        .route("/api/auth/register", post(handlers::auth::register))
        .route("/api/auth/login", post(handlers::auth::login))
        .route("/api/bins", get(handlers::bins::get_bins))
        .route("/api/bins/:id", get(handlers::bins::get_bin))
        .merge(protected)
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive())
        .with_state(state)
}
