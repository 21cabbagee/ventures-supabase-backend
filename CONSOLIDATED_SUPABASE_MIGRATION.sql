-- ============================================================================
-- MASTER VENTURES UNIFIED BACKEND SCHEMA
-- Supabase / PostgreSQL 15+ Migration (Cloud & SQL Editor Compatible)
-- Author: Antigravity IDE Autonomous Systems
-- Description: Unifies Auth, Realtime, and Data Storage for all 42 Ventures
-- ============================================================================

-- Enable essential extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- 1. VENTURES REGISTRY & DIRECTORY (All 42 Ventures)
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

DO $$ BEGIN
    DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
    CREATE TRIGGER on_auth_user_created
        AFTER INSERT ON auth.users
        FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
EXCEPTION WHEN others THEN NULL;
END $$;

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
DO $$ BEGIN
  CREATE POLICY "Public can view ventures" ON public.ventures FOR SELECT USING (true);
  CREATE POLICY "Public can view active markets" ON public.veridex_markets FOR SELECT USING (true);
  CREATE POLICY "Public can view public trades" ON public.veridex_trades FOR SELECT USING (true);
  CREATE POLICY "Public can view public events" ON public.ventures_events FOR SELECT USING (visibility = 'public');
  CREATE POLICY "Public can view courses" ON public.operator_courses FOR SELECT USING (is_published = true);
  CREATE POLICY "Public can view swarm agents" ON public.swarm_agents FOR SELECT USING (true);
  CREATE POLICY "Public can view context graph" ON public.swarm_context_graph FOR SELECT USING (true);

  CREATE POLICY "Users view own profile" ON public.profiles FOR SELECT USING (auth.uid() = id);
  CREATE POLICY "Users update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id);

  CREATE POLICY "Users view own orders" ON public.veridex_orders FOR SELECT USING (auth.uid() = user_id);
  CREATE POLICY "Users create own orders" ON public.veridex_orders FOR INSERT WITH CHECK (auth.uid() = user_id);
  CREATE POLICY "Users cancel own orders" ON public.veridex_orders FOR UPDATE USING (auth.uid() = user_id);

  CREATE POLICY "Users view own positions" ON public.veridex_positions FOR SELECT USING (auth.uid() = user_id);

  CREATE POLICY "Users view and manage projects" ON public.propsoch_projects FOR ALL USING (auth.uid() = user_id);
  CREATE POLICY "Users track course progress" ON public.operator_progress FOR ALL USING (auth.uid() = user_id);
  CREATE POLICY "Merchants view dispute cases" ON public.dispute_cases FOR SELECT USING (auth.uid() = merchant_id);
EXCEPTION WHEN others THEN NULL;
END $$;

-- Enable Realtime replication
DO $$ BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.ventures_events;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_trades;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_markets;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.veridex_orders;
  ALTER PUBLICATION supabase_realtime ADD TABLE public.swarm_context_graph;
EXCEPTION WHEN others THEN NULL;
END $$;

-- ============================================================================
-- 11. SEED DATA: ALL 42 VENTURES, PREDICTION MARKETS & 300 AGENTS
-- ============================================================================

INSERT INTO public.ventures (slug, name, tagline, description, category, website_url, repo_url, status)
VALUES
  -- Flagships
  ('veridex-exchange', 'VERIDEX', 'Next-Gen Event Derivatives & Prediction Exchange', 'Sub-millisecond Rust matching engine with zero-arbitrage synthetic parity.', 'prediction', 'https://21cabbagee.github.io/veridex-exchange/', 'https://github.com/21cabbagee/veridex-exchange', 'live'),
  ('swarm-ops', 'SwarmOps', '300-Agent PARL Autonomous Swarm Mesh', 'Shared Context Graph, Stateless MCP, 70/20/10 Router, and durable checkpoints.', 'flagship', 'https://21cabbagee.github.io/swarm-ops/', 'https://github.com/21cabbagee/swarm-ops', 'live'),
  ('operator-academy', 'Operator Academy', 'Applied Autonomous Systems Learning Hub', 'Verified curriculum with Harvard/MIT frameworks and zero-cost LLM gateway.', 'flagship', 'https://21cabbagee.github.io/operator-academy/', 'https://github.com/21cabbagee/operator-academy', 'live'),
  ('propsoch-studio', 'Propsoch Studio', 'Local-First Real Estate Video Editor', 'Automated cut generation, transparent RERA metadata, and zero-cloud rendering.', 'flagship', 'https://21cabbagee.github.io/propsoch-studio/', 'https://github.com/21cabbagee/propsoch-studio', 'live'),
  ('founder-os', 'Founder OS', 'Autonomous Venture Engineering Operating System', 'Rapid build sprint execution engine for 12-hour full-stack shipping.', 'flagship', 'https://21cabbagee.github.io/founder-os/', 'https://github.com/21cabbagee/founder-os', 'live'),
  ('subarb-engine', 'SubArb Engine', 'Subscription Arbitrage & Estate Liquidation', 'Dead-man switch digital legacy vault and recurring spend audit.', 'flagship', 'https://21cabbagee.github.io/subarb-engine/', 'https://github.com/21cabbagee/subarb-engine', 'live'),
  ('capybara-delivery-3d', 'Capybara Delivery', '3D Physics Micro-Logistics Game', 'Simulation of autonomous package routing with dynamic physics.', 'flagship', 'https://21cabbagee.github.io/capybara-delivery-3d/', 'https://github.com/21cabbagee/capybara-delivery-3d', 'live'),

  -- Enterprise Unbundling
  ('redact-bridge', 'RedactBridge', 'Client-Side PHI/PII De-Identification Pipeline', 'Unbundles compliance from Snowflake and Databricks.', 'unbundling', 'https://21cabbagee.github.io/redact-bridge/', 'https://github.com/21cabbagee/redact-bridge', 'live'),
  ('dispute-shield', 'DisputeShield', 'Automated Chargeback Bank Rebuttal Dossier', 'Unbundles dispute resolution from Stripe and Shopify.', 'unbundling', 'https://21cabbagee.github.io/dispute-shield/', 'https://github.com/21cabbagee/dispute-shield', 'live'),
  ('agent-lock', 'AgentLock', 'Task-Scoped Ephemeral API Token Scoper', 'Unbundles agent observability from enterprise SOC platforms.', 'unbundling', 'https://21cabbagee.github.io/agent-lock/', 'https://github.com/21cabbagee/agent-lock', 'live'),
  ('payout-cert', 'PayoutCert', 'Automated IRS W-8BEN Tax Treaty Validator', 'Unbundles contractor compliance from Deel and Rippling.', 'unbundling', 'https://21cabbagee.github.io/payout-cert/', 'https://github.com/21cabbagee/payout-cert', 'live'),

  -- Distribution & Media
  ('attention-drop', 'AttentionDrop', 'Physical Outbound Executive Pitch Bakery', '30%+ executive response rate direct mail orchestration.', 'distribution', 'https://21cabbagee.github.io/attention-drop/', 'https://github.com/21cabbagee/attention-drop', 'live'),
  ('spec-studio', 'SpecStudio', 'AI Media Service-as-a-Software Dispatch', 'Automated video generation with 5x margin governor.', 'distribution', 'https://21cabbagee.github.io/spec-studio/', 'https://github.com/21cabbagee/spec-studio', 'live'),
  ('idea-forge', 'IdeaForge', 'Master Taxonomy Orchestrator for 25 Micro-SaaS', 'High-leverage algorithmic ideation and validation.', 'distribution', 'https://21cabbagee.github.io/idea-forge/', 'https://github.com/21cabbagee/idea-forge', 'live'),
  ('bigset-workflow', 'Bigset Workflow', 'Self-Refreshing Funded Startup Intelligence', 'Real-time pipeline of newly funded companies and hiring signals.', 'distribution', 'https://21cabbagee.github.io/bigset-workflow/', 'https://github.com/21cabbagee/bigset-workflow', 'live'),

  -- 12-Hour Rapid Builds
  ('context-pulse', 'ContextPulse', 'Context Window Bloat & Compression Diagnostic', 'Analyzes LLM token consumption and dead context.', 'rapid_build', 'https://21cabbagee.github.io/context-pulse/', 'https://github.com/21cabbagee/context-pulse', 'live'),
  ('brief-pilot', 'BriefPilot', 'Async Video & Loom Spec-to-Ticket Generator', 'Converts unstructured video walkthroughs into Linear tickets.', 'rapid_build', 'https://21cabbagee.github.io/brief-pilot/', 'https://github.com/21cabbagee/brief-pilot', 'live'),
  ('recall-log', 'RecallLog', 'Conversational Memory Log & Semantic Retrieval', 'Long-term vector memory for autonomous AI agents.', 'rapid_build', 'https://21cabbagee.github.io/recall-log/', 'https://github.com/21cabbagee/recall-log', 'live'),
  ('vox-triage', 'VoxTriage', 'Interactive AI Voicemail for Solo Trades', 'Handles inbound emergency calls and estimates triage.', 'rapid_build', 'https://21cabbagee.github.io/vox-triage/', 'https://github.com/21cabbagee/vox-triage', 'live'),
  ('snap-action', 'SnapAction', 'Visual Screenshot-to-Action Shopping Agent', 'Extracts product intent from social screenshots.', 'rapid_build', 'https://21cabbagee.github.io/snap-action/', 'https://github.com/21cabbagee/snap-action', 'live'),
  ('omni-find', 'OmniFind', 'Universal Semantic Search Across Local Drives', 'Natural language local disk indexer with privacy preservation.', 'rapid_build', 'https://21cabbagee.github.io/omni-find/', 'https://github.com/21cabbagee/omni-find', 'live'),
  ('eval-agent', 'EvalAgent', 'Autonomous Agent Output Benchmarker', 'Automated grading and regression tracking across LLM versions.', 'rapid_build', 'https://21cabbagee.github.io/eval-agent/', 'https://github.com/21cabbagee/eval-agent', 'live'),
  ('guard-agent', 'GuardAgent', 'Prompt Injection & Exfiltration Firewall', 'Pre-flight and post-flight guardrails for enterprise LLM apps.', 'rapid_build', 'https://21cabbagee.github.io/guard-agent/', 'https://github.com/21cabbagee/guard-agent', 'live'),
  ('screen-sop', 'ScreenSOP', 'Screen Action Recorder to Markdown SOP', 'Turns manual browser clicks into production-grade SOPs.', 'rapid_build', 'https://21cabbagee.github.io/screen-sop/', 'https://github.com/21cabbagee/screen-sop', 'live'),
  ('persona-api', 'PersonaAPI', 'Universal Personal Context API', 'Standardized user persona schema for customized AI tools.', 'rapid_build', 'https://21cabbagee.github.io/persona-api/', 'https://github.com/21cabbagee/persona-api', 'live'),
  ('agent-ping', 'AgentPing', 'Unified Agent Notification Hub & Human Inbox', 'Consolidates notifications from 300+ agents into Slack/email.', 'rapid_build', 'https://21cabbagee.github.io/agent-ping/', 'https://github.com/21cabbagee/agent-ping', 'live'),
  ('agent-finops', 'AgentFinOps', 'Autonomous Agent Token & API Spend Governor', 'Hard cost caps and circuit breakers for agent swarms.', 'rapid_build', 'https://21cabbagee.github.io/agent-finops/', 'https://github.com/21cabbagee/agent-finops', 'live'),

  -- Validated Pivots
  ('tribe-dinner', 'TribeDinner', 'High-Niche Micro-Salons & Private Dinners', 'Curated intimate gatherings for verified founders.', 'validated_pivot', 'https://21cabbagee.github.io/tribe-dinner/', 'https://github.com/21cabbagee/tribe-dinner', 'live'),
  ('contract-guard', 'ContractGuard', 'The Freelancer Lawyer & Automated MSA Redline', 'Detects predatory clauses in client contracts.', 'validated_pivot', 'https://21cabbagee.github.io/contract-guard/', 'https://github.com/21cabbagee/contract-guard', 'live'),
  ('petpass-b2b', 'PetPass B2B', 'Cross-Border Pet Relocation Regulatory Vault', 'Automated international pet travel health certificates.', 'validated_pivot', 'https://21cabbagee.github.io/petpass-b2b/', 'https://github.com/21cabbagee/petpass-b2b', 'live'),
  ('sub-vault', 'SubVault', 'Digital Legacy Vault & Zombie Subscription Killer', 'Safeguards online identities and terminates recurring fees on death.', 'validated_pivot', 'https://21cabbagee.github.io/sub-vault/', 'https://github.com/21cabbagee/sub-vault', 'live'),
  ('fieldtext-ai', 'FieldText AI', 'Zero-Data SMS Copilot for Field Trades', 'Generates quotes and invoices directly over Twilio SMS.', 'validated_pivot', 'https://21cabbagee.github.io/fieldtext-ai/', 'https://github.com/21cabbagee/fieldtext-ai', 'live'),
  ('stake-guard', 'StakeGuard', 'Financial Escrow Loss-Aversion Screen Blocker', 'Penalizes phone screen time via smart contract escrows.', 'validated_pivot', 'https://21cabbagee.github.io/stake-guard/', 'https://github.com/21cabbagee/stake-guard', 'live'),
  ('society-salon', 'SocietySalon', 'Gated Community Salon Collective', 'Hyper-local beauty and salon services inside residential towers.', 'validated_pivot', 'https://21cabbagee.github.io/society-salon/', 'https://github.com/21cabbagee/society-salon', 'live'),
  ('clean-drive', 'CleanDrive', 'Apartment Tower Carpet & Extraction Drive', 'Density-based group booking discounts for home cleaning.', 'validated_pivot', 'https://21cabbagee.github.io/clean-drive/', 'https://github.com/21cabbagee/clean-drive', 'live'),
  ('society-amc', 'SocietyAMC', 'Gated Community Appliance Maintenance AMC', 'Annual maintenance contracts for residential high-rises.', 'validated_pivot', 'https://21cabbagee.github.io/society-amc/', 'https://github.com/21cabbagee/society-amc', 'live'),

  -- Emerging Markets
  ('souk-link', 'SoukLink', 'GCC Wholesale Fragrance & Oud Escrow', 'B2B marketplace for luxury perfumery distribution across MENA.', 'emerging_market', 'https://21cabbagee.github.io/souk-link/', 'https://github.com/21cabbagee/souk-link', 'live'),
  ('famcare-global', 'FamCare Global', 'NRI Diaspora Elder Care Concierge', 'Verified hospital accompaniment and health concierge for aging parents.', 'emerging_market', 'https://21cabbagee.github.io/famcare-global/', 'https://github.com/21cabbagee/famcare-global', 'live'),
  ('shift-flow', 'ShiftFlow', 'GCC Construction Logistics & Bus Dispatcher', 'Optimizes transport for 5,000+ construction workers across job sites.', 'emerging_market', 'https://21cabbagee.github.io/shift-flow/', 'https://github.com/21cabbagee/shift-flow', 'live'),
  ('acre-guard', 'AcreGuard', 'Tier-2 India Farmland Title Verification', 'Satellite and revenue registry title clearance for agricultural land.', 'emerging_market', 'https://21cabbagee.github.io/acre-guard/', 'https://github.com/21cabbagee/acre-guard', 'live'),
  ('bilateral-pay', 'BilateralPay', 'UAE-India Rupee-Dirham Cross-Border Remittance', 'Direct settlement bypassing multi-day SWIFT intermediary banks.', 'emerging_market', 'https://21cabbagee.github.io/bilateral-pay/', 'https://github.com/21cabbagee/bilateral-pay', 'live'),
  ('viral-launch-showcase', 'Viral Launch Showcase', 'Master Venture Showcase & Viral Distribution Hub', 'Centralized showcase indexing all 42 live production applications.', 'emerging_market', 'https://21cabbagee.github.io/viral-launch-showcase/', 'https://github.com/21cabbagee/viral-launch-showcase', 'live')
ON CONFLICT (slug) DO UPDATE 
SET website_url = EXCLUDED.website_url, 
    repo_url = EXCLUDED.repo_url, 
    updated_at = timezone('utc'::text, now());

-- Seed VERIDEX Prediction Markets
INSERT INTO public.veridex_markets (slug, title, description, category, status, yes_price, no_price, volume_24h, volume_total, liquidity, open_interest, num_traders, resolver)
VALUES
  ('trump-wins-2024', 'Will Trump win the 2024 US Presidential Election?', 'Resolves YES if Donald Trump officially wins the 2024 US Presidential Election per the National Archives.', 'politics', 'ACTIVE', 0.73, 0.27, 4250000.00, 28500000.00, 1200000.00, 3100000.00, 48291, 'VERIDEX Oracle Committee / AP News'),
  ('btc-100k-2024', 'Will Bitcoin reach $100,000 before December 31, 2024?', 'Resolves YES if BTC/USD spot index reaches $100,000.00 on major exchanges before midnight Dec 31, 2024 UTC.', 'crypto', 'ACTIVE', 0.82, 0.18, 8100000.00, 41200000.00, 3400000.00, 7200000.00, 92847, 'Chainlink Decentralized Oracle Feed'),
  ('fed-rate-cut-dec-2024', 'Will the Federal Reserve cut rates by 25bps+ in December 2024?', 'Resolves YES if FOMC lowers federal funds rate target by 25 basis points or more during December 2024 meeting.', 'finance', 'ACTIVE', 0.61, 0.39, 2700000.00, 9800000.00, 880000.00, 1900000.00, 21440, 'Federal Reserve Board Statement'),
  ('chiefs-sb-2025', 'Will the Kansas City Chiefs win Super Bowl LIX?', 'Resolves YES if the Kansas City Chiefs win Super Bowl LIX in February 2025.', 'sports', 'ACTIVE', 0.32, 0.68, 1900000.00, 6600000.00, 540000.00, 1200000.00, 15621, 'NFL Official Box Score'),
  ('agi-benchmark-2025', 'Will an AI model score 90%+ on GPQA Diamond before Q3 2025?', 'Resolves YES if any verified frontier AI laboratory releases a model achieving 90% accuracy on GPQA Diamond.', 'science', 'ACTIVE', 0.58, 0.42, 1420000.00, 3890000.00, 410000.00, 890000.00, 12410, 'Epoch AI / Benchmark Evaluation Committee')
ON CONFLICT (slug) DO NOTHING;

-- Seed SwarmOps Initial Agents
INSERT INTO public.swarm_agents (agent_index, name, role, token_budget)
SELECT 
    i,
    'Agent-' || LPAD(i::text, 3, '0'),
    CASE 
        WHEN i <= 50 THEN 'Research & Fact Retrieval'
        WHEN i <= 120 THEN 'Code Architecture & Execution'
        WHEN i <= 200 THEN 'Data Ingestion & Cleaning'
        WHEN i <= 260 THEN 'Security Auditing & Red Teaming'
        ELSE 'Synthesis & Output Formatting'
    END,
    128000
FROM generate_series(1, 300) AS i
ON CONFLICT (agent_index) DO NOTHING;
