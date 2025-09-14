-- Create database if it doesn't exist
SELECT 'CREATE DATABASE medisupply'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'medisupply')\gexec

-- Connect to the medisupply database
\c medisupply;

-- Create extensions that might be needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Create a schema for the application (optional)
-- CREATE SCHEMA IF NOT EXISTS medisupply;

-- Set default search path (optional)
-- ALTER DATABASE medisupply SET search_path TO medisupply, public;

-- Create a basic health check function
CREATE OR REPLACE FUNCTION health_check()
RETURNS TEXT AS $$
BEGIN
    RETURN 'Database is healthy at ' || NOW();
END;
$$ LANGUAGE plpgsql;