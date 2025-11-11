-- Update Supabase Database for Multi-User Support
-- Run this SQL in Supabase SQL Editor
-- Project: https://supabase.com/dashboard/project/oqjcbjgidnybvvzecrhg/sql

-- ============================================
-- 1. ADD user_id COLUMNS
-- ============================================

-- Add user_id column to asin_master
ALTER TABLE asin_master ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- Add user_id column to invoices
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- Add user_id column to advertising
ALTER TABLE advertising ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- Add user_id column to vret_cogs
ALTER TABLE vret_cogs ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id);

-- ============================================
-- 2. CREATE INDEXES ON user_id
-- ============================================

CREATE INDEX IF NOT EXISTS idx_asin_master_user_id ON asin_master(user_id);
CREATE INDEX IF NOT EXISTS idx_invoices_user_id ON invoices(user_id);
CREATE INDEX IF NOT EXISTS idx_advertising_user_id ON advertising(user_id);
CREATE INDEX IF NOT EXISTS idx_vret_cogs_user_id ON vret_cogs(user_id);

-- ============================================
-- 3. UPDATE RLS POLICIES
-- ============================================

-- Enable RLS on all tables first
ALTER TABLE asin_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE advertising ENABLE ROW LEVEL SECURITY;
ALTER TABLE vret_cogs ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies on each table (regardless of name)
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN
        SELECT policyname, tablename
        FROM pg_policies
        WHERE tablename IN ('asin_master', 'invoices', 'advertising', 'vret_cogs')
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON %I', pol.policyname, pol.tablename);
    END LOOP;
END $$;

-- Create new user-specific policies for asin_master
CREATE POLICY "Users can access own asin_master" ON asin_master
    FOR ALL USING (auth.uid() = user_id);

-- Create new user-specific policies for invoices
CREATE POLICY "Users can access own invoices" ON invoices
    FOR ALL USING (auth.uid() = user_id);

-- Create new user-specific policies for advertising
CREATE POLICY "Users can access own advertising" ON advertising
    FOR ALL USING (auth.uid() = user_id);

-- Create new user-specific policies for vret_cogs
CREATE POLICY "Users can access own vret_cogs" ON vret_cogs
    FOR ALL USING (auth.uid() = user_id);

-- ============================================
-- 4. VERIFY SETUP
-- ============================================

-- Check that RLS is enabled on all tables
SELECT schemaname, tablename, rowsecurity
FROM pg_tables
WHERE tablename IN ('asin_master', 'invoices', 'advertising', 'vret_cogs')
ORDER BY tablename;

-- Check policies
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('asin_master', 'invoices', 'advertising', 'vret_cogs')
ORDER BY tablename, policyname;

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Verify all 4 tables have user_id column
-- 2. Verify RLS policies are in place
-- 3. Test by logging in and creating data
-- ============================================
