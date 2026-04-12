CREATE TABLE bin_reports (
    id          UUID        PRIMARY KEY DEFAULT uuid_generate_v4(),
    bin_id      UUID        NOT NULL REFERENCES bins(id) ON DELETE CASCADE,
    reported_by UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    report_type VARCHAR     NOT NULL,
    comment     TEXT,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
