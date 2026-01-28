-- Fix tenant_fc01 schema permissions - corrected version

-- Step 1: Grant usage on schema to anon and authenticated roles
GRANT USAGE ON SCHEMA tenant_fc01 TO anon;
GRANT USAGE ON SCHEMA tenant_fc01 TO authenticated;
GRANT USAGE ON SCHEMA tenant_fc01 TO service_role;

-- Step 2: Grant permissions on all tables in tenant_fc01 schema
DO supabase\migrations\20260128050000_configure_tenant_fc01_exposed.sql
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
END supabase\migrations\20260128050000_configure_tenant_fc01_exposed.sql;

-- Step 3: Create a function to check schema access
CREATE OR REPLACE FUNCTION tenant_fc01.check_schema_access()
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS supabase\migrations\20260128050000_configure_tenant_fc01_exposed.sql
  SELECT true;
supabase\migrations\20260128050000_configure_tenant_fc01_exposed.sql;

-- Grant access to the function
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO anon;
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO authenticated;
GRANT EXECUTE ON FUNCTION tenant_fc01.check_schema_access() TO service_role;

-- Add comment
COMMENT ON SCHEMA tenant_fc01 IS 'Schema isolado para tenant_fc01 - dados separados do projeto principal';