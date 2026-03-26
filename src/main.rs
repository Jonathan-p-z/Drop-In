mod config;
mod db;
mod errors;
mod handlers;
mod middleware;
mod models;
mod routes;

use crate::errors::AppError;
use tracing_subscriber::EnvFilter;

#[tokio::main]
async fn main() -> Result<(), AppError> {
    dotenv::dotenv().ok();

    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::from_default_env())
        .init();

    let settings = config::Settings::from_env()?;
    let pool = db::create_pool(&settings).await?;

    let state = routes::AppState {
        pool,
        jwt_secret: settings.jwt_secret.clone(),
        jwt_expiry_hours: settings.jwt_expiry_hours,
    };

    let app = routes::router(state);
    let addr = format!("{}:{}", settings.server_host, settings.server_port);

    tracing::info!("listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(&addr)
        .await
        .map_err(|err| AppError::Internal(err.to_string()))?;

    axum::serve(listener, app)
        .await
        .map_err(|err| AppError::Internal(err.to_string()))?;

    Ok(())
}
