use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    // Payload d'identite minimal; on etend quand l'auth est stabilisee.
    pub id: Uuid,
    pub email: String,
    pub created_at: DateTime<Utc>,
}
