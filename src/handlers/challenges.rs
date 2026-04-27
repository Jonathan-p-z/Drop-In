use axum::{
    extract::{Extension, Path, State},
    response::IntoResponse,
    Json,
};
use chrono::Utc;
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{
        ChallengeResponse, ChallengeRow, ChallengeWithProgressRow, ProgressResponse,
        UserChallengeRow,
    },
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

pub async fn update_progress(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
    Path(challenge_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let mut tx = state.pool.begin().await?;

    let challenge = sqlx::query_as::<_, ChallengeRow>(
        "SELECT id, target_count, points_reward, expires_at
         FROM challenges WHERE id = $1",
    )
    .bind(challenge_id)
    .fetch_optional(&mut *tx)
    .await?
    .ok_or_else(|| AppError::NotFound("Défi introuvable".to_string()))?;

    if challenge.expires_at < Utc::now() {
        return Err(AppError::Validation("Ce défi est expiré".to_string()));
    }

    // Upsert : crée ou incrémente, sans toucher aux lignes déjà complétées
    let uc = sqlx::query_as::<_, UserChallengeRow>(
        "INSERT INTO user_challenges (user_id, challenge_id, progress)
         VALUES ($1, $2, 1)
         ON CONFLICT (user_id, challenge_id) DO UPDATE
             SET progress = CASE
                 WHEN user_challenges.completed_at IS NULL
                 THEN user_challenges.progress + 1
                 ELSE user_challenges.progress
             END
         RETURNING id, user_id, challenge_id, progress, completed_at, created_at",
    )
    .bind(user_id)
    .bind(challenge_id)
    .fetch_one(&mut *tx)
    .await?;

    // Déjà complété avant cet appel : renvoie l'état sans modifier les points
    if uc.completed_at.is_some() {
        tx.commit().await?;
        return Ok(Json(ProgressResponse {
            challenge_id,
            progress: uc.progress,
            target_count: challenge.target_count,
            is_completed: true,
            points_awarded: None,
        }));
    }

    let just_completed = uc.progress >= challenge.target_count;
    let points_awarded = if just_completed {
        let now = Utc::now();
        sqlx::query(
            "UPDATE user_challenges SET completed_at = $1 WHERE id = $2",
        )
        .bind(now)
        .bind(uc.id)
        .execute(&mut *tx)
        .await?;

        sqlx::query("UPDATE users SET points = points + $1 WHERE id = $2")
            .bind(challenge.points_reward)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;

        Some(challenge.points_reward)
    } else {
        None
    };

    tx.commit().await?;

    Ok(Json(ProgressResponse {
        challenge_id,
        progress: uc.progress,
        target_count: challenge.target_count,
        is_completed: just_completed,
        points_awarded,
    }))
}
