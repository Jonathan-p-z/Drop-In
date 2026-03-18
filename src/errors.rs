use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde::Serialize;
use std::fmt;

#[derive(Debug)]
pub enum AppError {
    Config(String),
    Database(sqlx::Error),
    Jwt(jsonwebtoken::errors::Error),
    Internal(String),
}

impl fmt::Display for AppError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            AppError::Config(message) => write!(f, "Config error: {}", message),
            AppError::Database(err) => write!(f, "Database error: {}", err),
            AppError::Jwt(err) => write!(f, "JWT error: {}", err),
            AppError::Internal(message) => write!(f, "Internal error: {}", message),
        }
    }
}

impl std::error::Error for AppError {}

impl From<sqlx::Error> for AppError {
    fn from(err: sqlx::Error) -> Self {
        Self::Database(err)
    }
}

impl From<jsonwebtoken::errors::Error> for AppError {
    fn from(err: jsonwebtoken::errors::Error) -> Self {
        Self::Jwt(err)
    }
}

#[derive(Serialize)]
struct ErrorResponse {
    error: String,
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        // Mapping centralise: handlers propres et evolutions plus sures.
        let (status, message) = match &self {
            AppError::Config(message) => (StatusCode::INTERNAL_SERVER_ERROR, message.clone()),
            AppError::Database(_) => (StatusCode::INTERNAL_SERVER_ERROR, "Database error".to_string()),
            AppError::Jwt(_) => (StatusCode::UNAUTHORIZED, "Invalid token".to_string()),
            AppError::Internal(message) => (StatusCode::INTERNAL_SERVER_ERROR, message.clone()),
        };

        (status, Json(ErrorResponse { error: message })).into_response()
    }
}
