
-- ============================================================================
-- SCRIPT DE CONFIGURAÇÃO DO STORAGE
-- ============================================================================

-- 1. Criar o bucket 'efd-files' se não existir
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'efd-files', 
    'efd-files', 
    false, 
    104857600, -- 100MB
    ARRAY['text/plain', 'text/csv', 'application/octet-stream']
)
ON CONFLICT (id) DO UPDATE SET 
    public = false,
    file_size_limit = 104857600,
    allowed_mime_types = ARRAY['text/plain', 'text/csv', 'application/octet-stream'];

-- 2. Habilitar RLS no bucket (já é padrão, mas garantindo)
-- Nota: RLS em storage.objects é o que importa

-- 3. Políticas de Segurança para 'efd-files'

-- Política: Usuários autenticados podem fazer upload de arquivos
CREATE POLICY "Authenticated users can upload efd files"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'efd-files' AND
    auth.role() = 'authenticated'
);

-- Política: Usuários podem ver seus próprios arquivos (baseado no caminho do arquivo ou metadados)
-- Assumindo que o caminho do arquivo contenha o user_id ou que validamos de outra forma.
-- Por simplificação inicial, permitimos que quem fez upload veja (owner).
CREATE POLICY "Users can view their own efd files"
ON storage.objects FOR SELECT
TO authenticated
USING (
    bucket_id = 'efd-files' AND
    owner = auth.uid()
);

-- Política: Service Role tem acesso total
CREATE POLICY "Service Role has full access to efd files"
ON storage.objects FOR ALL
TO service_role
USING (bucket_id = 'efd-files')
WITH CHECK (bucket_id = 'efd-files');

-- 4. (Opcional) Política para permitir download se for necessário processamento público (não recomendado para EFD)

