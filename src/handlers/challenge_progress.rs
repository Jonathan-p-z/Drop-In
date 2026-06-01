use uuid::Uuid;

use crate::{
    errors::AppError,
    models::{ChallengeRow, UserChallengeRow},
};

pub async fn increment_challenge_progress(
    pool: &sqlx::PgPool,
    user_id: Uuid,
    challenge_type: &str,
) -> Result<(), AppError> {
    // Récupère les défis actifs du type donné
    let challenges = sqlx::query_as::<_, ChallengeRow>(
        "SELECT id, target_count, points_reward, expires_at
         FROM challenges
         WHERE action_type = $1 AND expires_at > NOW()",
    )
    .bind(challenge_type)
    .fetch_all(pool)
    .await?;

    if challenges.is_empty() {
        return Ok(());
    }

    let mut tx = pool.begin().await?;

    for challenge in challenges {
        // Upsert : incrémente sans toucher aux lignes déjà complétées
        let uc = sqlx::query_as::<_, UserChallengeRow>(
            "INSERT INTO user_challenges (user_id, challenge_id, progress)
             VALUES ($1, $2, 1)
             ON CONFLICT (user_id, challenge_id) DO UPDATE
                 SET progress = CASE
                     WHEN user_challenges.completed_at IS NULL
                     THEN user_challenges.progress + 1
                     ELSE user_challenges.progress
                 END
             RETURNING id, user_id, challenge_id, progress, completed_at, created_at",
        )
        .bind(user_id)
        .bind(challenge.id)
        .fetch_one(&mut *tx)
        .await?;

        // Défi nouvellement complété : marque et attribue les points
        if uc.completed_at.is_none() && uc.progress >= challenge.target_count {
            sqlx::query("UPDATE user_challenges SET completed_at = NOW() WHERE id = $1")
                .bind(uc.id)
                .execute(&mut *tx)
                .await?;

            sqlx::query("UPDATE users SET points = points + $1 WHERE id = $2")
                .bind(challenge.points_reward)
                .bind(user_id)
                .execute(&mut *tx)
                .await?;
        }
    }

    tx.commit().await?;

    Ok(())
}
