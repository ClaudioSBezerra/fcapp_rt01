-- Expose tenant_fc01 schema for API access
-- Simple approach: just grant usage and basic permissions

-- Grant schema usage
GRANT USAGE ON SCHEMA tenant_fc01 TO anon, authenticated, service_role;

-- Grant permissions on all existing tables
GRANT SELECT ON ALL TABLES IN SCHEMA tenant_fc01 TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA tenant_fc01 TO service_role;

-- Grant permissions on future tables
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT SELECT ON TABLES TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA tenant_fc01 GRANT ALL ON TABLES TO service_role;

-- Grant function permissions
GRANT EXECUTE ON ALL ROUTINES IN SCHEMA tenant_fc01 TO anon, authenticated, service_role;

-- Test function
CREATE OR REPLACE FUNCTION tenant_fc01.test_connection()
RETURNS text
LANGUAGE sql
SECURITY DEFINER
AS list
    SELECT 'tenant_fc01 schema is accessible' as result;
list;

-- Grant access to test function
GRANT EXECUTE ON FUNCTION tenant_fc01.test_connection() TO anon, authenticated, service_role;