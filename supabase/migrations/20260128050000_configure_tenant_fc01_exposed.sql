-- Expose tenant_fc01 schema in PostgREST
-- This migration configures the tenant_fc01 schema to be accessible via the API

-- Step 1: Grant usage on schema to anon and authenticated roles
GRANT USAGE ON SCHEMA tenant_fc01 TO anon;
GRANT USAGE ON SCHEMA tenant_fc01 TO authenticated;
GRANT USAGE ON SCHEMA tenant_fc01 TO service_role;

-- Step 2: Grant permissions on all tables in tenant_fc01 schema
DO status
DECLARE
    table_record RECORD;
BEGIN
    -- Grant permissions to anon role
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'tenant_fc01'
          AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('GRANT SELECT ON TABLE tenant_fc01.%I TO anon', table_record.table_name);
        EXECUTE format('GRANT SELECT ON TABLE tenant_fc01.%I TO authenticated', table_record.table_name);
        EXECUTE format('GRANT ALL ON TABLE tenant_fc01.%I TO service_role', table_record.table_name);
    END LOOP;
    
    -- Grant permissions on views
    FOR table_record IN
        SELECT table_name
        FROM information_schema.views
        WHERE table_schema = 'tenant_fc01'
    LOOP
        EXECUTE format('GRANT SELECT ON TABLE tenant_fc01.%I TO anon', table_record.table_name);
        EXECUTE format('GRANT SELECT ON TABLE tenant_fc01.%I TO authenticated', table_record.table_name);
        EXECUTE format('GRANT ALL ON TABLE tenant_fc01.%I TO service_role', table_record.table_name);
    END LOOP;
END status;

-- Step 3: Grant permissions on functions
DO status
DECLARE
    func_record RECORD;
BEGIN
    FOR func_record IN
        SELECT routine_name
        FROM information_schema.routines
        WHERE routine_schema = 'tenant_fc01'
          AND routine_type = 'FUNCTION'
    LOOP
        EXECUTE format('GRANT EXECUTE ON FUNCTION tenant_fc01.%I TO anon', func_record.routine_name);
        EXECUTE format('GRANT EXECUTE ON FUNCTION tenant_fc01.%I TO authenticated', func_record.routine_name);
        EXECUTE format('GRANT EXECUTE ON FUNCTION tenant_fc01.%I TO service_role', func_record.routine_name);
    END LOOP;
END status;

-- Step 4: Configure RLS policies for tenant_fc01 schema
-- Enable RLS on all tables in tenant_fc01
DO status
DECLARE
    table_record RECORD;
BEGIN
    FOR table_record IN
        SELECT table_name
        FROM information_schema.tables
        WHERE table_schema = 'tenant_fc01'
          AND table_type = 'BASE TABLE'
    LOOP
        EXECUTE format('ALTER TABLE tenant_fc01.%I ENABLE ROW LEVEL SECURITY', table_record.table_name);
    END LOOP;
END status;

-- Step 5: Add schema to PostgREST exposed schemas
-- This might need to be configured in Supabase dashboard
-- For now, we'll create a function to check schema access
CREATE OR REPLACE FUNCTION tenant_fc01.check_schema_access()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS status
  SELECT true;
status;

-- Grant access to the function
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO anon;
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO authenticated;
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO service_role;

COMMENT ON SCHEMA tenant_fc01 IS 'Schema isolado para tenant_fc01 - dados separados do projeto principal';