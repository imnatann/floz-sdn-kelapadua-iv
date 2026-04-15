-- FLOZ LMS - PostgreSQL Initialization Script
-- Creates the central database and grants tenant DB creation privileges

-- Grant postgres the ability to create databases (for tenant provisioning)
-- postgres user already has superuser privileges by default

-- Create a template for tenant databases
CREATE DATABASE floz_tenant_template OWNER postgres;

-- Connect to the template and set up extensions
\c floz_tenant_template;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
