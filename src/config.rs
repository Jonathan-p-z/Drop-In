use std::env;

use crate::errors::AppError;

#[derive(Debug, Clone)]
pub struct Settings {
    pub database_url: String,
    pub jwt_secret: String,
    pub jwt_expiry_hours: u64,
    pub server_host: String,
    pub server_port: u16,
}

impl Settings {
    pub fn from_env() -> Result<Self, AppError> {
        let database_url = get_env("DATABASE_URL")?;
        let jwt_secret = get_env("JWT_SECRET")?;

        let jwt_expiry_hours = env::var("JWT_EXPIRY_HOURS")
            .unwrap_or_else(|_| "24".to_string())
            .parse::<u64>()
            .map_err(|_| AppError::Config("JWT_EXPIRY_HOURS must be a valid u64".to_string()))?;

        let server_host = env::var("SERVER_HOST").unwrap_or_else(|_| "0.0.0.0".to_string());

        let server_port = env::var("SERVER_PORT")
            .unwrap_or_else(|_| "3000".to_string())
            .parse::<u16>()
            .map_err(|_| AppError::Config("SERVER_PORT must be a valid u16".to_string()))?;

        Ok(Self {
            database_url,
            jwt_secret,
            jwt_expiry_hours,
            server_host,
            server_port,
        })
    }
}

fn get_env(key: &str) -> Result<String, AppError> {
    env::var(key).map_err(|_| AppError::Config(format!("Missing env var: {}", key)))
}
