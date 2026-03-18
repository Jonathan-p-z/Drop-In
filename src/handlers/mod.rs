use axum::{
    extract::{ws::WebSocket, ws::WebSocketUpgrade, State},
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
    // Le WebSocket demarre ici; le detail du protocole est dans la boucle dessous.
    ws.on_upgrade(handle_socket)
}

async fn handle_socket(mut socket: WebSocket) {
    // Boucle provisoire; elle garde la connexion vivante pour la suite.
    while let Some(Ok(message)) = socket.recv().await {
        if matches!(message, axum::extract::ws::Message::Close(_)) {
            break;
        }
    }
}
