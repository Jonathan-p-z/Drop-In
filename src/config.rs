use std::env;

use crate::errors::AppError;

#[derive(Debug, Clone)]
pub struct Settings {
    pub database_url: String,
    pub jwt_secret: String,
    pub server_host: String,
    pub server_port: u16,
}

impl Settings {
    pub fn from_env() -> Result<Self, AppError> {
        // On echoue vite si la config manque; pas de demarrage a moitie configure.
        let database_url = get_env("DATABASE_URL")?;
        let jwt_secret = get_env("JWT_SECRET")?;
        let server_host = get_env("SERVER_HOST")?;
        let server_port = get_env("SERVER_PORT")?
            .parse::<u16>()
            .map_err(|_| AppError::Config("SERVER_PORT must be a valid u16".to_string()))?;

        Ok(Self {
            database_url,
            jwt_secret,
            server_host,
            server_port,
        })
    }
}

fn get_env(key: &str) -> Result<String, AppError> {
    env::var(key).map_err(|_| AppError::Config(format!("Missing env var {}", key)))
}
