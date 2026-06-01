use axum::{
    extract::{Extension, Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use sqlx::QueryBuilder;
use uuid::Uuid;

use crate::{errors::AppError, models::*, routes::AppState};

const VALID_WASTE_TYPES: &[&str] = &[
    "glass", "plastic", "paper", "cardboard", "bio", "electronic", "metal", "other",
];

const POINTS_PER_BIN_ADDED: i32 = 10;

#[derive(sqlx::FromRow)]
struct BinRow {
    id: Uuid,
    added_by: Option<Uuid>,
    latitude: f64,
    longitude: f64,
    description: Option<String>,
    address: Option<String>,
    photo_url: Option<String>,
    status: String,
    is_verified: bool,
    created_at: chrono::DateTime<chrono::Utc>,
    updated_at: chrono::DateTime<chrono::Utc>,
    waste_types: Vec<String>,
}

impl From<BinRow> for BinResponse {
    fn from(row: BinRow) -> Self {
        BinResponse {
            id: row.id,
            added_by: row.added_by,
            latitude: row.latitude,
            longitude: row.longitude,
            description: row.description,
            address: row.address,
            photo_url: row.photo_url,
            status: row.status,
            is_verified: row.is_verified,
            created_at: row.created_at,
            updated_at: row.updated_at,
            waste_types: row.waste_types,
        }
    }
}

const BIN_SELECT: &str =
    "SELECT b.id, b.added_by,
     ST_Y(b.location) AS latitude, ST_X(b.location) AS longitude,
     b.description, b.address, b.photo_url, b.status, b.is_verified,
     b.created_at, b.updated_at,
     COALESCE(array_agg(bt.waste_type) FILTER (WHERE bt.waste_type IS NOT NULL), ARRAY[]::varchar[]) AS waste_types
     FROM bins b LEFT JOIN bin_types bt ON bt.bin_id = b.id";

pub async fn get_bins(
    State(state): State<AppState>,
    Query(filters): Query<BinFilters>,
) -> Result<impl IntoResponse, AppError> {
    let mut qb = QueryBuilder::new(format!("{} WHERE 1=1", BIN_SELECT));

    if let (Some(lat), Some(lng)) = (filters.latitude, filters.longitude) {
        let radius = filters.radius_meters.unwrap_or(1000.0);
        qb.push(" AND ST_DWithin(b.location::geography, ST_SetSRID(ST_MakePoint(");
        qb.push_bind(lng);
        qb.push(", ");
        qb.push_bind(lat);
        qb.push("), 4326)::geography, ");
        qb.push_bind(radius);
        qb.push(")");
    }
    if let Some(ref wt) = filters.waste_type {
        qb.push(" AND b.id IN (SELECT bin_id FROM bin_types WHERE waste_type = ");
        qb.push_bind(wt.clone());
        qb.push(")");
    }
    if let Some(ref status) = filters.status {
        qb.push(" AND b.status = ");
        qb.push_bind(status.clone());
    }
    qb.push(" GROUP BY b.id");
    if let (Some(lat), Some(lng)) = (filters.latitude, filters.longitude) {
        qb.push(" ORDER BY ST_Distance(b.location::geography, ST_SetSRID(ST_MakePoint(");
        qb.push_bind(lng);
        qb.push(", ");
        qb.push_bind(lat);
        qb.push("), 4326)::geography)");
    }

    let bins = qb.build_query_as::<BinRow>().fetch_all(&state.pool).await?;
    Ok(Json(bins.into_iter().map(BinResponse::from).collect::<Vec<_>>()))
}

pub async fn get_bin(
    State(state): State<AppState>,
    Path(bin_id): Path<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let bin = sqlx::query_as::<_, BinRow>(&format!("{} WHERE b.id = $1 GROUP BY b.id", BIN_SELECT))
        .bind(bin_id)
        .fetch_optional(&state.pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Poubelle introuvable".to_string()))?;

    Ok(Json(BinResponse::from(bin)))
}

pub async fn create_bin(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
    Json(payload): Json<CreateBinRequest>,
) -> Result<impl IntoResponse, AppError> {
    if payload.latitude < -90.0 || payload.latitude > 90.0 {
        return Err(AppError::Validation(
            "La latitude doit être comprise entre -90 et 90".to_string(),
        ));
    }
    if payload.longitude < -180.0 || payload.longitude > 180.0 {
        return Err(AppError::Validation(
            "La longitude doit être comprise entre -180 et 180".to_string(),
        ));
    }
    if payload.waste_types.is_empty() {
        return Err(AppError::Validation("Au moins un type de déchet est requis".to_string()));
    }
    for wt in &payload.waste_types {
        if !VALID_WASTE_TYPES.contains(&wt.as_str()) {
            return Err(AppError::Validation(format!("Type de déchet invalide : {}", wt)));
        }
    }

    let mut tx = state.pool.begin().await?;

    let bin = sqlx::query_as::<_, Bin>(
        "INSERT INTO bins (added_by, location, description, address)
         VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326), $4, $5)
         RETURNING id, added_by,
           ST_Y(location) AS latitude, ST_X(location) AS longitude,
           description, address, photo_url, status, is_verified, created_at, updated_at",
    )
    .bind(user_id)
    .bind(payload.longitude)
    .bind(payload.latitude)
    .bind(&payload.description)
    .bind(&payload.address)
    .fetch_one(&mut *tx)
    .await?;

    for wt in &payload.waste_types {
        sqlx::query("INSERT INTO bin_types (bin_id, waste_type) VALUES ($1, $2)")
            .bind(bin.id)
            .bind(wt)
            .execute(&mut *tx)
            .await?;
    }

    sqlx::query("UPDATE users SET points = points + $2 WHERE id = $1")
        .bind(user_id)
        .bind(POINTS_PER_BIN_ADDED)
        .execute(&mut *tx)
        .await?;

    tx.commit().await?;

    super::challenge_progress::increment_challenge_progress(&state.pool, user_id, "add_bin").await?;

    Ok((StatusCode::CREATED, Json(BinResponse::from_bin(bin, payload.waste_types))))
}
