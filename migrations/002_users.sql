CREATE TABLE users (
    id           UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    username     VARCHAR     NOT NULL UNIQUE,
    email        VARCHAR     NOT NULL UNIQUE,
    password_hash VARCHAR    NOT NULL,
    avatar_url   VARCHAR,
    bio          TEXT,
    points       INTEGER     NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
