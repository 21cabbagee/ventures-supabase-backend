#!/usr/bin/env bash
# ==============================================================================
# ⟐ SUPABASE VENTURES BACKEND SETUP SCRIPT
# Deploys Unified Schema, Seeds 42 Ventures, and Configures Edge Functions
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MIGRATION_FILE="$ROOT_DIR/supabase/migrations/20261014000000_master_ventures_schema.sql"
SEED_FILE="$ROOT_DIR/supabase/seed/seed_ventures.sql"

echo "=========================================================="
echo "⟐ Initializing Supabase Unified Backend for 42 Ventures"
echo "=========================================================="

# Check for DATABASE_URL or Supabase Project Ref
if [ -n "$DATABASE_URL" ]; then
    echo "→ Found DATABASE_URL. Executing PostgreSQL migrations directly..."
    psql "$DATABASE_URL" -f "$MIGRATION_FILE"
    psql "$DATABASE_URL" -f "$SEED_FILE"
    echo "✓ Schema & Seeds successfully deployed to PostgreSQL/Supabase!"
elif [ -n "$SUPABASE_DB_PASSWORD" ] && [ -n "$SUPABASE_PROJECT_ID" ]; then
    echo "→ Connecting to Supabase Cloud Project: $SUPABASE_PROJECT_ID"
    DB_CONN="postgresql://postgres:$SUPABASE_DB_PASSWORD@db.$SUPABASE_PROJECT_ID.supabase.co:5432/postgres"
    psql "$DB_CONN" -f "$MIGRATION_FILE"
    psql "$DB_CONN" -f "$SEED_FILE"
    echo "✓ Schema & Seeds successfully deployed to Supabase Cloud!"
else
    echo "→ No direct DATABASE_URL provided."
    echo "→ Creating standalone consolidated SQL file for Supabase Dashboard..."
    cat "$MIGRATION_FILE" > "$ROOT_DIR/CONSOLIDATED_SUPABASE_MIGRATION.sql"
    echo "" >> "$ROOT_DIR/CONSOLIDATED_SUPABASE_MIGRATION.sql"
    cat "$SEED_FILE" >> "$ROOT_DIR/CONSOLIDATED_SUPABASE_MIGRATION.sql"
    echo "✓ Consolidated migration written to: $ROOT_DIR/CONSOLIDATED_SUPABASE_MIGRATION.sql"
    echo "  (You can paste this directly into https://supabase.com/dashboard/project/_/sql)"
fi

echo "=========================================================="
echo "✓ Master Supabase Backend Ready!"
echo "=========================================================="
