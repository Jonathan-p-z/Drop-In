use axum::{
    extract::{Query, State},
    response::IntoResponse,
    Json,
};

use crate::{
    errors::AppError,
    models::{LeaderboardEntry, LeaderboardQuery, LeaderboardRow},
    routes::AppState,
};

const MAX_LIMIT: i64 = 100;
const DEFAULT_LIMIT: i64 = 50;

pub async fn get_leaderboard(
    State(state): State<AppState>,
    Query(params): Query<LeaderboardQuery>,
) -> Result<impl IntoResponse, AppError> {
    let limit = params.limit.unwrap_or(DEFAULT_LIMIT).clamp(1, MAX_LIMIT);

    let rows = sqlx::query_as::<_, LeaderboardRow>(
        "SELECT id, username, avatar_url, points,
                ROW_NUMBER() OVER (ORDER BY points DESC) AS rank
         FROM users
         ORDER BY points DESC
         LIMIT $1",
    )
    .bind(limit)
    .fetch_all(&state.pool)
    .await?;

    let entries: Vec<LeaderboardEntry> = rows.into_iter().map(LeaderboardEntry::from).collect();
    Ok(Json(entries))
}
