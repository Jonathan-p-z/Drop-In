use axum::{
    extract::{Extension, Multipart, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use base64::{engine::general_purpose::STANDARD, Engine};
use serde::{Deserialize, Serialize};
use serde_json::json;
use uuid::Uuid;

use crate::{errors::AppError, routes::AppState};

const MAX_IMAGE_SIZE: usize = 10 * 1024 * 1024; // 10 Mo

const SYSTEM_PROMPT: &str =
    "Tu es un assistant de tri des déchets. Analyse cette image et réponds UNIQUEMENT en JSON \
     avec ce format exact : {\"dechet\": \"nom du déchet\", \"categorie\": \
     \"verre|plastique|papier|carton|bio|electronique|metal|autre\", \
     \"instruction\": \"où et comment le jeter en France\", \
     \"confiance\": \"haute|moyenne|faible\"}. \
     Si tu ne vois pas de déchet, mets confiance: faible.";

#[derive(Debug, Serialize, Deserialize)]
pub struct ScanResult {
    pub dechet: String,
    pub categorie: String,
    pub instruction: String,
    pub confiance: String,
}

pub async fn analyze_image(
    State(state): State<AppState>,
    Extension(_user_id): Extension<Uuid>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::Validation(e.to_string()))?
    {
        if field.name() != Some("image") {
            continue;
        }

        let content_type = field.content_type().unwrap_or("image/jpeg").to_string();
        if !content_type.starts_with("image/") {
            return Err(AppError::Validation(
                "Le fichier doit être une image".to_string(),
            ));
        }

        let data = field
            .bytes()
            .await
            .map_err(|e| AppError::Internal(e.to_string()))
            .inspect_err(|e| tracing::error!("{e}"))?;

        if data.len() > MAX_IMAGE_SIZE {
            return Err(AppError::Validation(
                "L'image ne doit pas dépasser 10 Mo".to_string(),
            ));
        }

        let payload = json!({
            "system_instruction": {
                "parts": [{ "text": SYSTEM_PROMPT }]
            },
            "contents": [
                {
                    "parts": [
                        {
                            "inline_data": {
                                "mime_type": content_type,
                                "data": STANDARD.encode(&data)
                            }
                        }
                    ]
                }
            ],
            "generationConfig": {
                "maxOutputTokens": 300,
                "temperature": 0.1
            }
        });

        let url = format!(
            "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key={}",
            state.gemini_api_key
        );

        let response = state
            .http_client
            .post(&url)
            .json(&payload)
            .send()
            .await
            .map_err(|e| AppError::Internal(format!("Erreur appel Gemini : {}", e)))
            .inspect_err(|e| tracing::error!("{e}"))?;

        if !response.status().is_success() {
            let err_body: serde_json::Value = response.json().await.unwrap_or(json!({}));
            let msg = err_body["error"]["message"]
                .as_str()
                .unwrap_or("Erreur API Gemini");
            let err = AppError::Internal(format!("Gemini : {}", msg));
            tracing::error!("{err}");
            return Err(err);
        }

        let body: serde_json::Value = response
            .json()
            .await
            .map_err(|e| AppError::Internal(format!("Réponse Gemini invalide : {}", e)))
            .inspect_err(|e| tracing::error!("{e}"))?;

        let raw = body["candidates"][0]["content"]["parts"][0]["text"]
            .as_str()
            .ok_or_else(|| AppError::Internal("Réponse Gemini inattendue".to_string()))
            .inspect_err(|e| tracing::error!("{e}"))?;

        tracing::debug!("réponse brute Gemini : {raw}");

        // Supprime les éventuels blocs Markdown que le modèle pourrait générer
        let json_str = raw
            .trim()
            .trim_start_matches("```json")
            .trim_start_matches("```")
            .trim_end_matches("```")
            .trim();

        let result: ScanResult = serde_json::from_str(json_str)
            .map_err(|e| AppError::Internal(format!("Réponse IA non structurée : {}", e)))
            .inspect_err(|e| tracing::error!("{e}"))?;

        return Ok((StatusCode::OK, Json(result)));
    }

    Err(AppError::Validation(
        "Aucune image reçue — champ 'image' manquant".to_string(),
    ))
}
