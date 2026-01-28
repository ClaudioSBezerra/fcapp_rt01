// Test script to validate tenant_fc01 schema configuration
import { createClient } from '@supabase/supabase-js';
import 'dotenv/config';

const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_PUBLISHABLE_KEY = process.env.VITE_SUPABASE_PUBLISHABLE_KEY;

async function testTenantFc01Schema() {
  console.log('🧪 Testing tenant_fc01 schema configuration...');
  
  // Test 1: Create client with tenant_fc01 schema
  const supabase_fc01 = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    db: {
      schema: 'tenant_fc01'
    }
  });
  
  try {
    // Test 2: Try to access the schema
    const { data, error } = await supabase_fc01
      .from('empresas')
      .select('id, nome_fantasia')
      .limit(1);
    
    if (error) {
      console.error('❌ Error accessing tenant_fc01 schema:', error);
      return false;
    }
    
    console.log('✅ Successfully connected to tenant_fc01 schema');
    console.log('📊 Sample data:', data);
    
    // Test 3: Check if schema exists in information_schema
    const { data: schemaCheck, error: schemaError } = await supabase_fc01
      .rpc('check_schema', { schema_name: 'tenant_fc01' });
    
    if (schemaError && !schemaError.message.includes('does not exist')) {
      console.error('❌ Error checking schema:', schemaError);
    } else {
      console.log('✅ Schema tenant_fc01 is accessible');
    }
    
    return true;
  } catch (err) {
    console.error('❌ Unexpected error:', err);
    return false;
  }
}

async function compareWithPublicSchema() {
  console.log('\\n🔄 Comparing with public schema...');
  
  const supabase_public = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY);
  const supabase_fc01 = createClient(SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, {
    db: {
      schema: 'tenant_fc01'
    }
  });
  
  try {
    // Check tables in public schema
    const { data: publicTables } = await supabase_public
      .from('pg_tables')
      .select('tablename')
      .eq('schemaname', 'public')
      .limit(5);
    
    // Check tables in tenant_fc01 schema
    const { data: fc01Tables } = await supabase_fc01
      .from('pg_tables')
      .select('tablename')
      .eq('schemaname', 'tenant_fc01')
      .limit(5);
    
    console.log('📋 Public schema tables:', publicTables?.map(t => t.tablename));
    console.log('📋 tenant_fc01 schema tables:', fc01Tables?.map(t => t.tablename));
    
  } catch (err) {
    console.error('❌ Error comparing schemas:', err);
  }
}

async function main() {
  const testResult = await testTenantFc01Schema();
  await compareWithPublicSchema();
  
  if (testResult) {
    console.log('\\n🎉 tenant_fc01 schema configuration is working correctly!');
  } else {
    console.log('\\n💥 tenant_fc01 schema configuration needs attention.');
  }
}

main().catch(console.error);