-- ============================================================================
-- SCRIPT COMPLETO DE CRIAÇÃO DO BANCO DE DADOS (V2 - CONSOLIDADO)
-- Sistema de Gestão Tributária - Reforma Tributária
-- Data: 2026-01-27
-- ============================================================================

-- SEÇÃO 1: EXTENSÕES E SCHEMAS
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE SCHEMA IF NOT EXISTS extensions;

-- SEÇÃO 2: TIPOS ENUMERADOS
DO $$ BEGIN
    CREATE TYPE public.app_role AS ENUM ('admin', 'user', 'viewer');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE public.subscription_status AS ENUM ('trial', 'active', 'cancelled', 'past_due');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- SEÇÃO 3: TABELAS PRINCIPAIS

-- 3.1 TENANTS
CREATE TABLE IF NOT EXISTS public.tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    nome TEXT NOT NULL DEFAULT 'Meu Ambiente',
    subscription_status text DEFAULT 'active',
    stripe_customer_id TEXT,
    stripe_subscription_id TEXT,
    trial_started_at TIMESTAMPTZ,
    trial_ends_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.2 PROFILES
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY, -- References auth.users(id)
    email TEXT NOT NULL,
    full_name TEXT,
    recovery_city TEXT,
    recovery_dob DATE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.3 USER_ROLES
CREATE TABLE IF NOT EXISTS public.user_roles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    role public.app_role NOT NULL DEFAULT 'user',
    created_at TIMESTAMPTZ DEFAULT now(),
    CONSTRAINT user_roles_user_id_key UNIQUE (user_id)
);

-- 3.4 USER_TENANTS
CREATE TABLE IF NOT EXISTS public.user_tenants (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT user_tenants_user_id_tenant_id_key UNIQUE (user_id, tenant_id)
);

-- 3.5 GRUPOS_EMPRESAS
CREATE TABLE IF NOT EXISTS public.grupos_empresas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.6 EMPRESAS
CREATE TABLE IF NOT EXISTS public.empresas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    grupo_id UUID NOT NULL REFERENCES public.grupos_empresas(id) ON DELETE CASCADE,
    nome TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.7 FILIAIS
CREATE TABLE IF NOT EXISTS public.filiais (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    cnpj VARCHAR(14) NOT NULL,
    razao_social TEXT NOT NULL,
    nome_fantasia TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.8 ALIQUOTAS
CREATE TABLE IF NOT EXISTS public.aliquotas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    ano INTEGER NOT NULL UNIQUE,
    ibs_estadual NUMERIC NOT NULL DEFAULT 0,
    ibs_municipal NUMERIC NOT NULL DEFAULT 0,
    cbs NUMERIC NOT NULL DEFAULT 0,
    reduc_icms NUMERIC NOT NULL DEFAULT 0,
    reduc_piscofins NUMERIC NOT NULL DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.9 MERCADORIAS
CREATE TABLE IF NOT EXISTS public.mercadorias (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filial_id UUID NOT NULL REFERENCES public.filiais(id) ON DELETE CASCADE,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('entrada', 'saida')),
    mes_ano DATE NOT NULL,
    ncm VARCHAR(10),
    descricao TEXT,
    valor NUMERIC NOT NULL DEFAULT 0,
    pis NUMERIC NOT NULL DEFAULT 0,
    cofins NUMERIC NOT NULL DEFAULT 0,
    icms NUMERIC DEFAULT 0,
    ipi NUMERIC DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.10 FRETES
CREATE TABLE IF NOT EXISTS public.fretes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filial_id UUID NOT NULL REFERENCES public.filiais(id) ON DELETE CASCADE,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('credito', 'debito')),
    mes_ano DATE NOT NULL,
    ncm VARCHAR(10),
    descricao TEXT,
    cnpj_transportadora VARCHAR(14),
    valor NUMERIC NOT NULL DEFAULT 0,
    pis NUMERIC NOT NULL DEFAULT 0,
    cofins NUMERIC NOT NULL DEFAULT 0,
    icms NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.11 ENERGIA_AGUA
CREATE TABLE IF NOT EXISTS public.energia_agua (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filial_id UUID NOT NULL REFERENCES public.filiais(id) ON DELETE CASCADE,
    tipo_operacao VARCHAR(10) NOT NULL CHECK (tipo_operacao IN ('credito', 'debito')),
    tipo_servico VARCHAR(20) NOT NULL CHECK (tipo_servico IN ('energia', 'agua', 'gas', 'comunicacao')),
    mes_ano DATE NOT NULL,
    descricao TEXT,
    cnpj_fornecedor VARCHAR(14),
    valor NUMERIC NOT NULL DEFAULT 0,
    pis NUMERIC NOT NULL DEFAULT 0,
    cofins NUMERIC NOT NULL DEFAULT 0,
    icms NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.12 IMPORT_JOBS
CREATE TABLE IF NOT EXISTS public.import_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    empresa_id UUID NOT NULL REFERENCES public.empresas(id) ON DELETE CASCADE,
    filial_id UUID REFERENCES public.filiais(id) ON DELETE SET NULL,
    file_path TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_size BIGINT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
    progress INTEGER NOT NULL DEFAULT 0,
    total_lines INTEGER NOT NULL DEFAULT 0,
    bytes_processed BIGINT DEFAULT 0,
    chunk_number INTEGER DEFAULT 0,
    record_limit INTEGER DEFAULT 0,
    import_scope TEXT NOT NULL DEFAULT 'all',
    counts JSONB NOT NULL DEFAULT '{"fretes": 0, "mercadorias": 0, "energia_agua": 0}'::jsonb,
    error_message TEXT,
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3.13 IMPORT_JOB_LOGS (Novo)
CREATE TABLE IF NOT EXISTS public.import_job_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    job_id uuid NOT NULL REFERENCES public.import_jobs(id) ON DELETE CASCADE,
    level text CHECK (level IN ('info', 'warning', 'error')),
    message text NOT NULL,
    line_number integer,
    raw_content text,
    created_at timestamp with time zone DEFAULT now()
);

-- 3.14 AUDIT_LOGS
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    tenant_id UUID NOT NULL REFERENCES public.tenants(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    table_name TEXT,
    record_count INTEGER,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT now()
);

-- 3.15 SERVICOS (Consolidado)
CREATE TABLE IF NOT EXISTS public.servicos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    filial_id UUID NOT NULL REFERENCES public.filiais(id) ON DELETE CASCADE,
    tipo VARCHAR(10) NOT NULL CHECK (tipo IN ('entrada', 'saida')),
    mes_ano DATE NOT NULL,
    descricao TEXT,
    valor NUMERIC NOT NULL DEFAULT 0,
    pis NUMERIC NOT NULL DEFAULT 0,
    cofins NUMERIC NOT NULL DEFAULT 0,
    iss NUMERIC NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- SEÇÃO 4: ÍNDICES
CREATE INDEX IF NOT EXISTS idx_mercadorias_filial_id ON public.mercadorias(filial_id);
CREATE INDEX IF NOT EXISTS idx_mercadorias_mes_ano ON public.mercadorias(mes_ano DESC);
CREATE INDEX IF NOT EXISTS idx_fretes_filial_id ON public.fretes(filial_id);
CREATE INDEX IF NOT EXISTS idx_energia_agua_filial_id ON public.energia_agua(filial_id);
CREATE INDEX IF NOT EXISTS idx_import_jobs_user_id ON public.import_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_import_job_logs_job_id ON public.import_job_logs(job_id);
CREATE INDEX IF NOT EXISTS idx_servicos_unique_content ON public.servicos (filial_id, mes_ano, tipo, COALESCE(descricao, ''), valor, pis, cofins, iss);

-- SEÇÃO 5: DADOS PADRÃO (AMB_DEMO)
INSERT INTO public.tenants (id, nome, subscription_status)
VALUES ('11111111-1111-1111-1111-111111111111', 'AMB_DEMO', 'active')
ON CONFLICT (id) DO UPDATE SET nome = 'AMB_DEMO', subscription_status = 'active';

INSERT INTO public.grupos_empresas (id, tenant_id, nome)
VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'AMB_DEMO_GRUPO')
ON CONFLICT (id) DO UPDATE SET nome = 'AMB_DEMO_GRUPO';

INSERT INTO public.tenants (nome, subscription_status)
SELECT 'AMB_PRD', 'active'
WHERE NOT EXISTS (SELECT 1 FROM public.tenants WHERE nome = 'AMB_PRD');

-- SEÇÃO 6: VIEWS E FUNÇÕES AUXILIARES

-- View de Monitoramento
CREATE OR REPLACE VIEW public.vw_import_job_stats AS
SELECT 
    j.id,
    j.file_name,
    j.status,
    j.progress,
    j.total_lines,
    j.created_at,
    j.updated_at,
    EXTRACT(EPOCH FROM (j.updated_at - j.started_at)) as duration_seconds,
    (j.counts->>'mercadorias')::int + (j.counts->>'servicos')::int + (j.counts->>'fretes')::int + (j.counts->>'energia_agua')::int as total_records,
    (SELECT COUNT(*) FROM public.import_job_logs l WHERE l.job_id = j.id AND l.level = 'warning') as warning_count,
    (SELECT COUNT(*) FROM public.import_job_logs l WHERE l.job_id = j.id AND l.level = 'error') as error_count
FROM public.import_jobs j;

-- Trigger Updated At
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;

-- Aplica triggers (exemplo para tenants)
DROP TRIGGER IF EXISTS set_updated_at ON public.tenants;
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.tenants FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- RLS (Exemplo básico - Habilitar em todas as tabelas)
ALTER TABLE public.tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_tenants ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.grupos_empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.empresas ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.filiais ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.import_job_logs ENABLE ROW LEVEL SECURITY;

-- Políticas RLS básicas (Permissiva para setup inicial - DEVE SER REFINADA)
CREATE POLICY "Allow Service Role" ON public.tenants FOR ALL TO service_role USING (true) WITH CHECK (true);
CREATE POLICY "Allow Service Role" ON public.profiles FOR ALL TO service_role USING (true) WITH CHECK (true);
-- Adicionar mais políticas conforme necessário
