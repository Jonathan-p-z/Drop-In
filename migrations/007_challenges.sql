CREATE TABLE challenges (
    id             UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    title          VARCHAR     NOT NULL,
    description    TEXT,
    challenge_type VARCHAR     NOT NULL CHECK (challenge_type IN ('daily', 'weekly', 'monthly')),
    target_count   INTEGER     NOT NULL DEFAULT 1 CHECK (target_count > 0),
    points_reward  INTEGER     NOT NULL DEFAULT 10 CHECK (points_reward >= 0),
    expires_at     TIMESTAMPTZ NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE user_challenges (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id UUID        NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    progress     INTEGER     NOT NULL DEFAULT 0 CHECK (progress >= 0),
    completed_at TIMESTAMPTZ,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (user_id, challenge_id)
);

-- Données initiales : quelques défis de démonstration
INSERT INTO challenges (title, description, challenge_type, target_count, points_reward, expires_at) VALUES
  ('Premier pas', 'Signalez votre première poubelle', 'daily', 1, 20,
   NOW() + INTERVAL '1 day'),
  ('Patrouilleur', 'Ajoutez 3 poubelles sur la carte', 'weekly', 3, 50,
   NOW() + INTERVAL '7 days'),
  ('Éco-héros', 'Scannez 5 déchets avec l''IA', 'weekly', 5, 75,
   NOW() + INTERVAL '7 days'),
  ('Gardien du quartier', 'Signalez 10 poubelles pleines', 'monthly', 10, 150,
   NOW() + INTERVAL '30 days');
