use axum::{extract::State, http::StatusCode, response::IntoResponse, Json};
use chrono::Utc;
use jsonwebtoken::{encode, EncodingKey, Header};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{AuthResponse, LoginRequest, RegisterRequest, User, UserResponse},
    routes::AppState,
};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
    iat: usize,
}

fn generate_token(user_id: Uuid, secret: &str, expiry_hours: u64) -> Result<String, AppError> {
    let now = Utc::now().timestamp() as usize;
    let claims = Claims {
        sub: user_id.to_string(),
        exp: now + (expiry_hours as usize * 3600),
        iat: now,
    };
    encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )
    .map_err(AppError::Jwt)
}

fn is_valid_email(email: &str) -> bool {
    let parts: Vec<&str> = email.splitn(2, '@').collect();
    if parts.len() != 2 {
        return false;
    }
    let (local, domain) = (parts[0], parts[1]);
    !local.is_empty() && domain.contains('.') && domain.len() > 2
}

pub async fn register(
    State(state): State<AppState>,
    Json(payload): Json<RegisterRequest>,
) -> Result<impl IntoResponse, AppError> {
    if !is_valid_email(&payload.email) {
        return Err(AppError::Validation("L'adresse email n'est pas valide".to_string()));
    }
    if payload.username.trim().is_empty() {
        return Err(AppError::Validation("Le nom d'utilisateur ne peut pas être vide".to_string()));
    }
    if payload.password.len() < 8 {
        return Err(AppError::Validation(
            "Le mot de passe doit contenir au moins 8 caractères".to_string(),
        ));
    }

    let existing = sqlx::query("SELECT id FROM users WHERE username = $1 OR email = $2")
        .bind(&payload.username)
        .bind(&payload.email)
        .fetch_optional(&state.pool)
        .await?;

    if existing.is_some() {
        return Err(AppError::Validation(
            "Ce nom d'utilisateur ou cet email est déjà utilisé".to_string(),
        ));
    }

    let password_hash = bcrypt::hash(&payload.password, bcrypt::DEFAULT_COST)
        .map_err(|e| AppError::Internal(e.to_string()))?;

    let user = sqlx::query_as::<_, User>(
        r#"
        INSERT INTO users (username, email, password_hash)
        VALUES ($1, $2, $3)
        RETURNING id, username, email, password_hash, avatar_url, bio, points, created_at, updated_at
        "#,
    )
    .bind(&payload.username)
    .bind(&payload.email)
    .bind(&password_hash)
    .fetch_one(&state.pool)
    .await?;

    let token = generate_token(user.id, &state.jwt_secret, state.jwt_expiry_hours)?;
    Ok((StatusCode::CREATED, Json(AuthResponse {
        token,
        user: UserResponse::from(user),
    })))
}

pub async fn login(
    State(state): State<AppState>,
    Json(payload): Json<LoginRequest>,
) -> Result<impl IntoResponse, AppError> {
    let user = sqlx::query_as::<_, User>(
        "SELECT id, username, email, password_hash, avatar_url, bio, points, created_at, updated_at
         FROM users WHERE email = $1",
    )
    .bind(&payload.email)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(|| AppError::Unauthorized("Email ou mot de passe incorrect".to_string()))?;

    let password_matches = bcrypt::verify(&payload.password, &user.password_hash)
        .map_err(|e| AppError::Internal(e.to_string()))?;

    if !password_matches {
        return Err(AppError::Unauthorized("Email ou mot de passe incorrect".to_string()));
    }

    let token = generate_token(user.id, &state.jwt_secret, state.jwt_expiry_hours)?;
    Ok(Json(AuthResponse {
        token,
        user: UserResponse::from(user),
    }))
}
