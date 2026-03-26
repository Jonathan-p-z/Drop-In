use axum::{
    extract::{Request, State},
    http::header,
    middleware::Next,
    response::Response,
};
use jsonwebtoken::{decode, DecodingKey, Validation};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use crate::{errors::AppError, routes::AppState};

#[derive(Debug, Serialize, Deserialize)]
struct Claims {
    sub: String,
    exp: usize,
    iat: usize,
}

pub async fn require_auth(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    let token = req
        .headers()
        .get(header::AUTHORIZATION)
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.strip_prefix("Bearer "))
        .ok_or_else(|| AppError::Unauthorized("Token manquant ou malformé".to_string()))?;

    let token_data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(state.jwt_secret.as_bytes()),
        &Validation::default(),
    )
    .map_err(|_| AppError::Unauthorized("Token invalide ou expiré".to_string()))?;

    let user_id = Uuid::parse_str(&token_data.claims.sub)
        .map_err(|_| AppError::Unauthorized("Token corrompu".to_string()))?;

    req.extensions_mut().insert(user_id);
    Ok(next.run(req).await)
}
