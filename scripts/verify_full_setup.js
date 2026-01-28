
import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
dotenv.config({ path: path.resolve(__dirname, '../.env') });

const supabaseUrl = process.env.VITE_SUPABASE_URL;
const supabaseServiceKey = process.env.VITE_SUPABASE_SERVICE_ROLE_KEY;

if (!supabaseUrl || !supabaseServiceKey) {
  console.error('Missing credentials');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseServiceKey);

async function verifySetup() {
  console.log('--- Verificando Banco de Dados ---');
  
  // 1. Verificar Tenant AMB_DEMO
  const { data: tenants, error: tenantError } = await supabase
    .from('tenants')
    .select('*')
    .eq('nome', 'AMB_DEMO');

  if (tenantError) {
    console.error('❌ Erro ao consultar tenants:', tenantError.message);
  } else if (tenants.length > 0) {
    console.log('✅ Tenant AMB_DEMO encontrado:', tenants[0].id);
  } else {
    console.error('❌ Tenant AMB_DEMO NÃO encontrado.');
  }

  // 2. Verificar Tabela de Logs (Nova)
  const { error: logError } = await supabase
    .from('import_job_logs')
    .select('count', { count: 'exact', head: true });

  if (logError) {
    console.error('❌ Tabela import_job_logs parece não existir ou sem acesso:', logError.message);
  } else {
    console.log('✅ Tabela import_job_logs verificada.');
  }

  console.log('\n--- Verificando Storage ---');
  
  // 3. Verificar Bucket
  const { data: buckets, error: bucketError } = await supabase.storage.listBuckets();
  
  if (bucketError) {
    console.error('❌ Erro ao listar buckets:', bucketError.message);
  } else {
    const efdBucket = buckets.find(b => b.name === 'efd-files');
    if (efdBucket) {
      console.log('✅ Bucket "efd-files" já existe.');
    } else {
      console.log('⚠️ Bucket "efd-files" NÃO existe. Tentando criar...');
      const { data, error: createError } = await supabase.storage.createBucket('efd-files', {
        public: false,
        fileSizeLimit: 104857600, // 100MB
        allowedMimeTypes: ['text/plain', 'text/csv', 'application/octet-stream']
      });
      
      if (createError) {
        console.error('❌ Falha ao criar bucket:', createError.message);
      } else {
        console.log('✅ Bucket "efd-files" criado com sucesso!');
      }
    }
  }
}

verifySetup();
