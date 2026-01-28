
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

// Load .env from project root
const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Error: Missing VITE_SUPABASE_URL or VITE_SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

console.log(`Connecting to ${supabaseUrl}...`);

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function validate() {
  try {
    // Try to list buckets as a connectivity test
    const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
    
    if (bucketError) {
      console.error('Connection failed (Storage check):', bucketError.message);
      // Fallback: try a simple query to a system table
    } else {
      console.log('✅ Connection successful! Buckets found:', buckets.length);
    }

    // Check if we can access the database
    // information_schema access might be restricted depending on RLS/Permissions, but service_role usually has access
    const { data, error } = await supabase
      .from('information_schema.tables')
      .select('count')
      .limit(1);

    // Note: querying information_schema directly via postgrest might fail if not exposed. 
    // Let's try to just query a non-existent table and see if we get a "relation does not exist" (which means connected) or "fetch failed".
    
    // Better: Query `auth.users` using admin api to verify admin access
    const { data: users, error: userError } = await supabase.auth.admin.listUsers({ perPage: 1 });
    
    if (userError) {
      console.error('❌ Auth Admin check failed:', userError.message);
    } else {
      console.log('✅ Auth Admin check successful. Users count:', users.users.length);
    }

  } catch (err) {
    console.error('Unexpected error:', err);
  }
}

validate();
