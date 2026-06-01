pub mod auth;
pub mod bin_reports;
pub mod bins;
pub mod challenge_progress;
pub mod challenges;
pub mod leaderboard;
pub mod photos;
pub mod scanner;
pub mod users;

use axum::{
    extract::{
        ws::{WebSocket, WebSocketUpgrade},
        State,
    },
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;

use crate::routes::AppState;

pub async fn health(State(_state): State<AppState>) -> impl IntoResponse {
    (StatusCode::OK, Json(json!({ "status": "ok" })))
}

pub async fn ws_handler(ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    while let Some(Ok(message)) = socket.recv().await {
        if matches!(message, axum::extract::ws::Message::Close(_)) {
            break;
        }
    }
}
