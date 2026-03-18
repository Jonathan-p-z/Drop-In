use sqlx::{postgres::PgPoolOptions, PgPool};

use crate::{config::Settings, errors::AppError};

pub async fn create_pool(settings: &Settings) -> Result<PgPool, AppError> {
    // Petit pool par defaut; on ajuste quand la charge est connue.
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&settings.database_url)
        .await?;

    Ok(pool)
}
