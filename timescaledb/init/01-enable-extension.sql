-- Enable TimescaleDB extension in the target database.
-- The timescale image auto-includes the shared_preload_libraries entry,
-- so `CREATE EXTENSION` is all that's needed at first-run.
CREATE EXTENSION IF NOT EXISTS timescaledb;
