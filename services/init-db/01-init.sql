-- Initialize medisupply database
CREATE DATABASE IF NOT EXISTS medisupply;

-- Create extension for UUID generation if needed
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE medisupply TO postgres;