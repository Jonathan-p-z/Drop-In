CREATE TABLE bins (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    added_by    UUID        REFERENCES users(id) ON DELETE SET NULL,
    location    GEOMETRY(Point, 4326) NOT NULL,
    description TEXT,
    address     VARCHAR,
    photo_url   VARCHAR,
    status      VARCHAR     NOT NULL DEFAULT 'unknown',
    is_verified BOOLEAN     NOT NULL DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
