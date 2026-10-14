-- ============================================================================
-- MASTER VENTURES UNIFIED BACKEND SCHEMA
-- Supabase / PostgreSQL 15+ Migration
-- Author: Antigravity IDE Autonomous Systems
-- Description: Unifies Auth, Realtime, and Data Storage for all 42 Ventures
-- ============================================================================

-- Enable essential extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. VENTURES REGISTRY & DIRECTORY
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ventures (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    tagline TEXT,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN (
        'flagship', 'unbundling', 'distribution', 'rapid_build', 'validated_pivot', 'emerging_market', 'prediction'
    )),
    website_url TEXT NOT NULL,
    repo_url TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'live' CHECK (status IN ('live', 'beta', 'maintenance', 'archived')),
    metrics JSONB DEFAULT '{"users": 0, "active_sessions": 0, "uptime": "99.9%"}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 2. UNIVERSAL USER PROFILES & WALLETS (Links with auth.users)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username TEXT UNIQUE,
    full_name TEXT,
    avatar_url TEXT,
    role TEXT NOT NULL DEFAULT 'user' CHECK (role IN ('user', 'trader', 'operator', 'admin')),
    balance_usd NUMERIC(14, 2) NOT NULL DEFAULT 10000.00 CHECK (balance_usd >= 0),
    locked_collateral NUMERIC(14, 2) NOT NULL DEFAULT 0.00 CHECK (locked_collateral >= 0),
    reputation_score INT DEFAULT 100,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 3. CROSS-VENTURE UNIFIED ACTIVITY & TELEMETRY STREAM
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.ventures_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venture_slug TEXT NOT NULL REFERENCES public.ventures(slug) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    visibility TEXT NOT NULL DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'internal')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE INDEX IF NOT EXISTS idx_ventures_events_slug_created ON public.ventures_events(venture_slug, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ventures_events_user ON public.ventures_events(user_id);

-- ============================================================================
-- 4. VERIDEX — PREDICTION MARKET & EVENT DERIVATIVES TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.veridex_markets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT NOT NULL CHECK (category IN ('politics', 'crypto', 'finance', 'sports', 'science', 'tech', 'other')),
    status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('DRAFT', 'ACTIVE', 'HALTED', 'RESOLVED', 'VOIDED')),
    yes_price NUMERIC(4, 2) NOT NULL DEFAULT 0.50 CHECK (yes_price >= 0.01 AND yes_price <= 0.99),
    no_price NUMERIC(4, 2) NOT NULL DEFAULT 0.50 CHECK (no_price >= 0.01 AND no_price <= 0.99),
    volume_24h NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    volume_total NUMERIC(16, 2) NOT NULL DEFAULT 0.00,
    liquidity NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    open_interest NUMERIC(14, 2) NOT NULL DEFAULT 0.00,
    num_traders INT NOT NULL DEFAULT 0,
    resolver TEXT NOT NULL DEFAULT 'VERIDEX Oracle Committee',
    resolution TEXT CHECK (resolution IN ('YES', 'NO', 'VOID')),
    closes_at TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.veridex_orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    market_id UUID NOT NULL REFERENCES public.veridex_markets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    outcome TEXT NOT NULL CHECK (outcome IN ('YES', 'NO')),
    side TEXT NOT NULL CHECK (side IN ('BUY', 'SELL')),
    order_type TEXT NOT NULL DEFAULT 'LIMIT' CHECK (order_type IN ('LIMIT', 'MARKET', 'FOK', 'IOC')),
    price NUMERIC(4, 2) NOT NULL CHECK (price >= 0.01 AND price <= 0.99),
    quantity NUMERIC(12, 2) NOT NULL CHECK (quantity > 0),
    quantity_filled NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    quantity_remaining NUMERIC(12, 2) NOT NULL,
    status TEXT NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'PARTIALLY_FILLED', 'FILLED', 'CANCELLED', 'EXPIRED')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.veridex_trades (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    market_id UUID NOT NULL REFERENCES public.veridex_markets(id) ON DELETE CASCADE,
    maker_order_id UUID REFERENCES public.veridex_orders(id) ON DELETE SET NULL,
    taker_order_id UUID REFERENCES public.veridex_orders(id) ON DELETE SET NULL,
    maker_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    taker_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    outcome TEXT NOT NULL CHECK (outcome IN ('YES', 'NO')),
    price NUMERIC(4, 2) NOT NULL,
    quantity NUMERIC(12, 2) NOT NULL,
    aggressor_side TEXT NOT NULL CHECK (aggressor_side IN ('BUY', 'SELL')),
    executed_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.veridex_positions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    market_id UUID NOT NULL REFERENCES public.veridex_markets(id) ON DELETE CASCADE,
    outcome TEXT NOT NULL CHECK (outcome IN ('YES', 'NO')),
    shares NUMERIC(12, 2) NOT NULL DEFAULT 0 CHECK (shares >= 0),
    avg_price NUMERIC(4, 2) NOT NULL,
    realized_pnl NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, market_id, outcome)
);

-- ============================================================================
-- 5. SWARMOPS — 300-AGENT MESH & CONTEXT GRAPH TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.swarm_agents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    agent_index INT UNIQUE NOT NULL CHECK (agent_index >= 1 AND agent_index <= 300),
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    parl_policy TEXT NOT NULL DEFAULT 'active_sampling_v3',
    token_budget INT NOT NULL DEFAULT 128000,
    tokens_consumed INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'idle' CHECK (status IN ('idle', 'executing', 'syncing', 'error')),
    last_heartbeat TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.swarm_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    prompt TEXT NOT NULL,
    assigned_agent_id UUID REFERENCES public.swarm_agents(id) ON DELETE SET NULL,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'running', 'completed', 'failed')),
    dag_checkpoint TEXT,
    execution_result JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    completed_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS public.swarm_context_graph (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    node_key TEXT UNIQUE NOT NULL,
    node_type TEXT NOT NULL,
    data JSONB NOT NULL DEFAULT '{}'::jsonb,
    confidence_score NUMERIC(3, 2) DEFAULT 0.95,
    updated_by_agent_index INT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 6. OPERATOR ACADEMY — LEARNING, MODULES & PROGRESS
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.operator_courses (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    slug TEXT UNIQUE NOT NULL,
    title TEXT NOT NULL,
    level TEXT NOT NULL CHECK (level IN ('introductory', 'intermediate', 'advanced', 'fellowship')),
    duration_hours INT NOT NULL DEFAULT 10,
    institution TEXT NOT NULL DEFAULT 'Operator Academy / MIT Verified',
    syllabus JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_published BOOLEAN NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS public.operator_progress (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    course_id UUID NOT NULL REFERENCES public.operator_courses(id) ON DELETE CASCADE,
    progress_pct INT NOT NULL DEFAULT 0 CHECK (progress_pct >= 0 AND progress_pct <= 100),
    certificate_id TEXT,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now()),
    UNIQUE(user_id, course_id)
);

-- ============================================================================
-- 7. PROPSOCH STUDIO & MEDIA PIPELINES
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.propsoch_projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    rera_number TEXT,
    property_type TEXT DEFAULT 'residential',
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'rendering', 'published')),
    raw_video_urls TEXT[] DEFAULT '{}',
    final_cut_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 8. ENTERPRISE ENGINES (RedactBridge, DisputeShield, AgentLock, PayoutCert)
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.enterprise_audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    venture TEXT NOT NULL,
    action TEXT NOT NULL,
    entity_id TEXT,
    sanitized_metadata JSONB DEFAULT '{}'::jsonb,
    ip_hash TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

CREATE TABLE IF NOT EXISTS public.dispute_cases (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    merchant_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    chargeback_amount NUMERIC(10, 2) NOT NULL,
    currency TEXT DEFAULT 'USD',
    status TEXT NOT NULL DEFAULT 'analyzing' CHECK (status IN ('analyzing', 'dossier_generated', 'submitted', 'won', 'lost')),
    rebuttal_pdf_url TEXT,
    evidence_score INT DEFAULT 85,
    created_at TIMESTAMPTZ NOT NULL DEFAULT timezone('utc'::text, now())
);

-- ============================================================================
-- 9. TRIGGERS: AUTO-UPDATE TIMESTAMP & PROFILE SYNCHRONIZATION
-- ============================================================================

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_ventures_updated_at BEFORE UPDATE ON public.ventures FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER tr_profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER tr_veridex_orders_updated_at BEFORE UPDATE ON public.veridex_orders FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Automatically create user profile when user registers via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, username, full_name, avatar_url, role)
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'username', split_part(NEW.email, '@', 1)),
        COALESCE(NEW.raw_user_meta_data->>'full_name', 'Verified Operator'),
        COALESCE(NEW.raw_user_meta_data->>'avatar_url', NULL),
        'user'
    ) ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ============================================================================
-- 10. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

ALTER TABLE public.ventures ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ventures_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veridex_markets ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veridex_orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veridex_trades ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.veridex_positions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swarm_agents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swarm_tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.swarm_context_graph ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operator_courses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.operator_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.propsoch_projects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.enterprise_audit_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.dispute_cases ENABLE ROW LEVEL SECURITY;

-- Public read for catalog and public feeds
CREATE POLICY "Public can view ventures" ON public.ventures FOR SELECT USING (true);
CREATE POLICY "Public can view active markets" ON public.veridex_markets FOR SELECT USING (true);
CREATE POLICY "Public can view public trades" ON public.veridex_trades FOR SELECT USING (true);
CREATE POLICY "Public can view public events" ON public.ventures_events FOR SELECT USING (visibility = 'public');
CREATE POLICY "Public can view courses" ON public.operator_courses FOR SELECT USING (is_published = true);
CREATE POLICY "Public can view swarm agents" ON public.swarm_agents FOR SELECT USING (true);
CREATE POLICY "Public can view context graph" ON public.swarm_context_graph FOR SELECT USING (true);

-- User-scoped policies
CREATE POLICY "Users view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users view own orders" ON public.veridex_orders FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users create own orders" ON public.veridex_orders FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users cancel own orders" ON public.veridex_orders FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users view own positions" ON public.veridex_positions FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users view and manage projects" ON public.propsoch_projects FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users track course progress" ON public.operator_progress FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Merchants view dispute cases" ON public.dispute_cases FOR SELECT USING (auth.uid() = merchant_id);

-- Enable Realtime replication on high-velocity tables
ALTER PUBLICATION supabase_realtime ADD TABLE public.ventures_events;
ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_trades;
ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_markets;
ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_orders;
ALTER PUBLICATION supabase_realtime ADD TABLE public.swarm_context_graph;
