use axum::{
    extract::{Extension, State},
    response::IntoResponse,
    Json,
};
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{ChallengeResponse, ChallengeWithProgressRow},
    routes::AppState,
};

const CHALLENGES_QUERY: &str =
    "SELECT c.id, c.title, c.description, c.challenge_type, c.target_count,
            c.points_reward, c.expires_at, c.created_at,
            COALESCE(uc.progress, 0)::int AS progress,
            uc.completed_at
     FROM challenges c
     LEFT JOIN user_challenges uc ON uc.challenge_id = c.id AND uc.user_id = $1
     WHERE c.expires_at > NOW()
     ORDER BY uc.completed_at NULLS FIRST, c.challenge_type, c.expires_at";

pub async fn get_challenges(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let rows = sqlx::query_as::<_, ChallengeWithProgressRow>(CHALLENGES_QUERY)
        .bind(user_id)
        .fetch_all(&state.pool)
        .await?;

    let challenges: Vec<ChallengeResponse> =
        rows.into_iter().map(ChallengeResponse::from).collect();

    Ok(Json(challenges))
}

