CREATE TABLE bin_types (
    id         UUID    PRIMARY KEY DEFAULT uuid_generate_v4(),
    bin_id     UUID    NOT NULL REFERENCES bins(id) ON DELETE CASCADE,
    waste_type VARCHAR NOT NULL
);
