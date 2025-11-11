-- Fix Invoice Duplicates Issue
-- Run this in Supabase SQL Editor to allow duplicate invoice line items

-- ============================================
-- 1. DROP THE UNIQUE CONSTRAINT
-- ============================================

-- This constraint prevents duplicate invoice_id + asin combinations
-- Dropping it allows same ASIN multiple times in same invoice
ALTER TABLE invoices DROP CONSTRAINT IF EXISTS invoices_vendor_invoice_id_asin_key;

-- ============================================
-- 2. ADD row_id COLUMN (Optional - for unique identification)
-- ============================================

-- Add a unique row identifier column
ALTER TABLE invoices ADD COLUMN IF NOT EXISTS row_id TEXT;

-- Create index on row_id
CREATE INDEX IF NOT EXISTS idx_invoices_row_id ON invoices(row_id);

-- ============================================
-- 3. VERIFY CHANGES
-- ============================================

-- Check constraints (should NOT see invoices_vendor_invoice_id_asin_key)
SELECT conname, contype
FROM pg_constraint
WHERE conrelid = 'invoices'::regclass;

-- Check columns (should see row_id)
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'invoices'
ORDER BY ordinal_position;

-- ============================================
-- COMPLETE!
-- ============================================
-- Now your app can save duplicate invoice line items
-- Same invoice ID can have same ASIN multiple times
-- ============================================
