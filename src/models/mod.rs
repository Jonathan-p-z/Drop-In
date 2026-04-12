use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct User {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    #[serde(skip_serializing)]
    pub password_hash: String,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub points: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct RegisterRequest {
    pub username: String,
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Serialize)]
pub struct UserResponse {
    pub id: Uuid,
    pub username: String,
    pub email: String,
    pub avatar_url: Option<String>,
    pub bio: Option<String>,
    pub points: i32,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

impl From<User> for UserResponse {
    fn from(u: User) -> Self {
        Self {
            id: u.id,
            username: u.username,
            email: u.email,
            avatar_url: u.avatar_url,
            bio: u.bio,
            points: u.points,
            created_at: u.created_at,
            updated_at: u.updated_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct AuthResponse {
    pub token: String,
    pub user: UserResponse,
}

// Modèle de base d'une poubelle — latitude/longitude extraits du champ geometry via ST_Y/ST_X
#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Bin {
    pub id: Uuid,
    pub added_by: Option<Uuid>,
    pub latitude: f64,
    pub longitude: f64,
    pub description: Option<String>,
    pub address: Option<String>,
    pub photo_url: Option<String>,
    pub status: String,
    pub is_verified: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BinType {
    pub id: Uuid,
    pub bin_id: Uuid,
    pub waste_type: String,
}

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct BinReport {
    pub id: Uuid,
    pub bin_id: Uuid,
    pub reported_by: Uuid,
    pub report_type: String,
    pub comment: Option<String>,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct CreateBinRequest {
    pub latitude: f64,
    pub longitude: f64,
    pub description: Option<String>,
    pub address: Option<String>,
    pub waste_types: Vec<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BinResponse {
    pub id: Uuid,
    pub added_by: Option<Uuid>,
    pub latitude: f64,
    pub longitude: f64,
    pub description: Option<String>,
    pub address: Option<String>,
    pub photo_url: Option<String>,
    pub status: String,
    pub is_verified: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub waste_types: Vec<String>,
}

impl BinResponse {
    pub fn from_bin(bin: Bin, waste_types: Vec<String>) -> Self {
        Self {
            id: bin.id,
            added_by: bin.added_by,
            latitude: bin.latitude,
            longitude: bin.longitude,
            description: bin.description,
            address: bin.address,
            photo_url: bin.photo_url,
            status: bin.status,
            is_verified: bin.is_verified,
            created_at: bin.created_at,
            updated_at: bin.updated_at,
            waste_types,
        }
    }
}

#[derive(Debug, Deserialize)]
pub struct CreateReportRequest {
    pub report_type: String,
    pub comment: Option<String>,
}

// Paramètres de requête pour filtrer les poubelles
#[derive(Debug, Deserialize)]
pub struct BinFilters {
    pub latitude: Option<f64>,
    pub longitude: Option<f64>,
    pub radius_meters: Option<f64>,
    pub waste_type: Option<String>,
    pub status: Option<String>,
}
