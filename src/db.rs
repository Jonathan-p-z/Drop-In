use sqlx::{postgres::PgPoolOptions, PgPool};

use crate::{config::Settings, errors::AppError};

pub async fn create_pool(settings: &Settings) -> Result<PgPool, AppError> {
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&settings.database_url)
        .await?;

    sqlx::migrate!()
        .run(&pool)
        .await
        .map_err(|err| AppError::Internal(format!("Migration failed: {}", err)))?;

    Ok(pool)
}
