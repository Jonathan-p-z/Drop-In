use axum::{extract::State, response::IntoResponse, Extension, Json};
use uuid::Uuid;

use crate::{errors::AppError, models::{User, UserResponse}, routes::AppState};

pub async fn me(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let user = sqlx::query_as::<_, User>(
        "SELECT id, username, email, password_hash, avatar_url, bio, points, created_at, updated_at
         FROM users WHERE id = $1",
    )
    .bind(user_id)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::NotFound("Utilisateur introuvable".to_string()))?;

    Ok(Json(UserResponse::from(user)))
}
