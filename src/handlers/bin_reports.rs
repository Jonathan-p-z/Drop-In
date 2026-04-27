use axum::{
    extract::{Extension, Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use sqlx::PgPool;
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{BinReport, CreateReportRequest},
    routes::AppState,
};

const VALID_REPORT_TYPES: &[&str] = &[
    "full", "empty", "wrong_info", "wrong_location", "duplicate", "removed",
];

const POINTS_PER_REPORT: i32 = 5;
const CONCORDANCE_THRESHOLD: i64 = 3;
const CONCORDANCE_WINDOW_HOURS: i64 = 24;
const STATUS_EXPIRY_HOURS: i64 = 48;

pub async fn report_bin(
    State(state): State<AppState>,
    Path(bin_id): Path<Uuid>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<CreateReportRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !VALID_REPORT_TYPES.contains(&payload.report_type.as_str()) {
        return Err(AppError::Validation(format!(
            "Type de signalement invalide : {}",
            payload.report_type
        )));
    }

    let exists: bool = sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM bins WHERE id = $1)")
        .bind(bin_id)
        .fetch_one(&state.pool)
        .await?;

    if !exists {
        return Err(AppError::NotFound("Poubelle introuvable".to_string()));
    }

    let report = sqlx::query_as::<_, BinReport>(
        "INSERT INTO bin_reports (bin_id, reported_by, report_type, comment)
         VALUES ($1, $2, $3, $4)
         RETURNING id, bin_id, reported_by, report_type, comment, created_at",
    )
    .bind(bin_id)
    .bind(user_id)
    .bind(&payload.report_type)
    .bind(&payload.comment)
    .fetch_one(&state.pool)
    .await?;

    if payload.report_type == "full" || payload.report_type == "empty" {
        let count: i64 = sqlx::query_scalar(&format!(
            "SELECT COUNT(*) FROM bin_reports
             WHERE bin_id = $1 AND report_type = $2
             AND created_at > NOW() - INTERVAL '{} hours'",
            CONCORDANCE_WINDOW_HOURS,
        ))
        .bind(bin_id)
        .bind(&payload.report_type)
        .fetch_one(&state.pool)
        .await?;

        if count >= CONCORDANCE_THRESHOLD {
            sqlx::query("UPDATE bins SET status = $1, updated_at = NOW() WHERE id = $2")
                .bind(&payload.report_type)
                .bind(bin_id)
                .execute(&state.pool)
                .await?;
        }
    }

    sqlx::query("UPDATE users SET points = points + $2 WHERE id = $1")
        .bind(user_id)
        .bind(POINTS_PER_REPORT)
        .execute(&state.pool)
        .await?;

    Ok((StatusCode::CREATED, Json(report)))
}

pub async fn reset_expired_bin_status(pool: &PgPool) -> Result<u64, AppError> {
    let affected = sqlx::query(&format!(
        "UPDATE bins SET status = 'unknown', updated_at = NOW()
         WHERE status != 'unknown'
         AND updated_at < NOW() - INTERVAL '{hours} hours'
         AND id NOT IN (
             SELECT DISTINCT bin_id FROM bin_reports
             WHERE created_at > NOW() - INTERVAL '{hours} hours'
         )",
        hours = STATUS_EXPIRY_HOURS,
    ))
    .execute(pool)
    .await?;

    Ok(affected.rows_affected())
}
