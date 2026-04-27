use axum::{
    extract::DefaultBodyLimit,
    middleware,
    routing::{get, patch, post},
    Router,
};
use sqlx::PgPool;
use tower_http::{cors::CorsLayer, services::ServeDir, trace::TraceLayer};

use crate::handlers;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub jwt_secret: String,
    pub jwt_expiry_hours: u64,
    pub http_client: reqwest::Client,
    pub gemini_api_key: String,
}

pub fn router(state: AppState) -> Router {
    let protected = Router::new()
        .route("/api/challenges", get(handlers::challenges::get_challenges))
        .route(
            "/api/challenges/:id/progress",
            post(handlers::challenges::update_progress),
        )
        .route("/api/users/me", get(handlers::users::me))
        .route("/api/users/me", patch(handlers::users::patch_me))
        .route(
            "/api/users/me/avatar",
            post(handlers::users::upload_avatar)
                .layer(DefaultBodyLimit::max(4_000_000)),
        )
        .route("/api/bins", post(handlers::bins::create_bin))
        .route("/api/bins/:id/report", post(handlers::bin_reports::report_bin))
        .route(
            "/api/bins/:id/photo",
            post(handlers::photos::upload_bin_photo)
                .layer(DefaultBodyLimit::max(6_000_000)),
        )
        .route(
            "/api/scanner/analyze",
            post(handlers::scanner::analyze_image)
                .layer(DefaultBodyLimit::max(10_000_000)),
        )
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
        .route("/api/leaderboard", get(handlers::leaderboard::get_leaderboard))
        .nest_service("/uploads", ServeDir::new("uploads"))
        .merge(protected)
        .layer(TraceLayer::new_for_http())
        .layer(CorsLayer::permissive())
        .with_state(state)
}
