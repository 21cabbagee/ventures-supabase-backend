-- ============================================================================
-- SEED DATA: All 42 Ventures + Initial Domain Data
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
