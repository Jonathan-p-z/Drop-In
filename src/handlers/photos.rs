use axum::{
    extract::{Extension, Multipart, Path, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;
use tokio::{fs, io::AsyncWriteExt};
use uuid::Uuid;

use crate::{errors::AppError, routes::AppState};

const MAX_FILE_SIZE: usize = 5 * 1024 * 1024; // 5 Mo
const ALLOWED_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "webp"];

pub async fn upload_bin_photo(
    State(state): State<AppState>,
    Path(bin_id): Path<Uuid>,
    Extension(_user_id): Extension<Uuid>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    let exists: bool = sqlx::query_scalar("SELECT EXISTS(SELECT 1 FROM bins WHERE id = $1)")
        .bind(bin_id)
        .fetch_one(&state.pool)
        .await?;

    if !exists {
        return Err(AppError::NotFound("Poubelle introuvable".to_string()));
    }

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::Validation(e.to_string()))?
    {
        if field.name() != Some("photo") {
            continue;
        }

        let content_type = field.content_type().unwrap_or("").to_string();
        if !content_type.starts_with("image/") {
            return Err(AppError::Validation(
                "Le fichier doit être une image".to_string(),
            ));
        }

        let original_name = field.file_name().unwrap_or("file").to_string();
        let ext = std::path::Path::new(&original_name)
            .extension()
            .and_then(|e| e.to_str())
            .unwrap_or("jpg")
            .to_lowercase();

        if !ALLOWED_EXTENSIONS.contains(&ext.as_str()) {
            return Err(AppError::Validation(format!(
                "Extension non autorisée : {}",
                ext
            )));
        }

        let data = field
            .bytes()
            .await
            .map_err(|e| AppError::Internal(e.to_string()))?;

        if data.len() > MAX_FILE_SIZE {
            return Err(AppError::Validation(
                "La photo ne doit pas dépasser 5 Mo".to_string(),
            ));
        }

        let filename = format!("{}.{}", Uuid::new_v4(), ext);
        let file_path = format!("uploads/{}", filename);

        let mut file = fs::File::create(&file_path).await.map_err(|e| {
            AppError::Internal(format!("Impossible d'écrire la photo : {}", e))
        })?;
        file.write_all(&data).await.map_err(|e| {
            AppError::Internal(format!("Impossible d'écrire la photo : {}", e))
        })?;

        let photo_url = format!("/uploads/{}", filename);

        sqlx::query("UPDATE bins SET photo_url = $1, updated_at = NOW() WHERE id = $2")
            .bind(&photo_url)
            .bind(bin_id)
            .execute(&state.pool)
            .await?;

        return Ok((StatusCode::OK, Json(json!({ "photo_url": photo_url }))));
    }

    Err(AppError::Validation(
        "Aucune photo reçue — champ 'photo' manquant".to_string(),
    ))
}
