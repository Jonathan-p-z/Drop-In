use axum::{
    extract::{Extension, Multipart, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;
use tokio::{fs, io::AsyncWriteExt};
use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{ProfileResponse, ProfileRow, UpdateProfileRequest},
    routes::AppState,
};

const MAX_AVATAR_SIZE: usize = 3 * 1024 * 1024;
const ALLOWED_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "webp"];

const PROFILE_QUERY: &str =
    "SELECT u.id, u.username, u.email, u.password_hash, u.avatar_url, u.bio, u.points,
            u.created_at, u.updated_at,
            (SELECT COUNT(*) FROM bins WHERE added_by = u.id) AS bins_added
     FROM users u WHERE u.id = $1";

pub async fn me(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
) -> Result<impl IntoResponse, AppError> {
    let row = sqlx::query_as::<_, ProfileRow>(PROFILE_QUERY)
        .bind(user_id)
        .fetch_optional(&state.pool)
        .await?
        .ok_or_else(|| AppError::NotFound("Utilisateur introuvable".to_string()))?;

    Ok(Json(ProfileResponse::from(row)))
}

pub async fn patch_me(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
    Json(body): Json<UpdateProfileRequest>,
) -> Result<impl IntoResponse, AppError> {
    if let Some(ref u) = body.username {
        if u.trim().is_empty() {
            return Err(AppError::Validation(
                "Le nom d'utilisateur ne peut pas être vide".to_string(),
            ));
        }
    }

    sqlx::query(
        "UPDATE users
         SET username   = COALESCE($1, username),
             bio        = COALESCE($2, bio),
             avatar_url = COALESCE($3, avatar_url),
             updated_at = NOW()
         WHERE id = $4",
    )
    .bind(&body.username)
    .bind(&body.bio)
    .bind(&body.avatar_url)
    .bind(user_id)
    .execute(&state.pool)
    .await?;

    let row = sqlx::query_as::<_, ProfileRow>(PROFILE_QUERY)
        .bind(user_id)
        .fetch_one(&state.pool)
        .await?;

    Ok(Json(ProfileResponse::from(row)))
}

pub async fn upload_avatar(
    State(state): State<AppState>,
    Extension(user_id): Extension<Uuid>,
    mut multipart: Multipart,
) -> Result<impl IntoResponse, AppError> {
    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::Validation(e.to_string()))?
    {
        if field.name() != Some("avatar") {
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

        if data.len() > MAX_AVATAR_SIZE {
            return Err(AppError::Validation(
                "L'avatar ne doit pas dépasser 3 Mo".to_string(),
            ));
        }

        fs::create_dir_all("uploads").await.ok();

        let filename = format!("avatar_{}_{}.{}", user_id, Uuid::new_v4(), ext);
        let file_path = format!("uploads/{}", filename);

        let mut file = fs::File::create(&file_path).await.map_err(|e| {
            AppError::Internal(format!("Impossible d'écrire l'avatar : {}", e))
        })?;
        file.write_all(&data).await.map_err(|e| {
            AppError::Internal(format!("Impossible d'écrire l'avatar : {}", e))
        })?;

        let avatar_url = format!("/uploads/{}", filename);

        sqlx::query("UPDATE users SET avatar_url = $1, updated_at = NOW() WHERE id = $2")
            .bind(&avatar_url)
            .bind(user_id)
            .execute(&state.pool)
            .await?;

        return Ok((StatusCode::OK, Json(json!({ "avatar_url": avatar_url }))));
    }

    Err(AppError::Validation(
        "Aucune image reçue — champ 'avatar' manquant".to_string(),
    ))
}
