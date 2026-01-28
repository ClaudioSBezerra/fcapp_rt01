-- Create tenant_fc01 schema for fcapp_rt01 project isolation
-- This ensures complete data separation from other projects

-- Create by new schema
CREATE SCHEMA IF NOT EXISTS tenant_fc01;

-- Grant necessary permissions
GRANT USAGE ON SCHEMA tenant_fc01 TO anon;
GRANT USAGE ON SCHEMA tenant_fc01 TO authenticated;
GRANT ALL PRIVILEGES ON SCHEMA tenant_fc01 TO service_role;

-- Set default privileges for future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT SELECT ON TABLES TO anon;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON TABLES TO authenticated;

-- Set default privileges for future functions and sequences
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON SEQUENCES TO authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON FUNCTIONS TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT EXECUTE ON FUNCTIONS TO authenticated;

-- Add comment for documentation
COMMENT ON SCHEMA tenant_fc01 IS 'Tenant schema for fcapp_rt01 project - isolated data storage';