-- Amazon P&L Dashboard - Supabase Database Setup
-- Run this SQL in Supabase SQL Editor to create all tables

-- ============================================
-- 1. ASIN MASTER TABLE (Product Pricing)
-- ============================================
CREATE TABLE IF NOT EXISTS asin_master (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    asin TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(vendor, asin)
);

CREATE INDEX IF NOT EXISTS idx_asin_master_vendor ON asin_master(vendor);
CREATE INDEX IF NOT EXISTS idx_asin_master_asin ON asin_master(asin);
CREATE INDEX IF NOT EXISTS idx_asin_master_created_at ON asin_master(created_at DESC);

-- ============================================
-- 2. INVOICES TABLE (Sales Transactions)
-- ============================================
CREATE TABLE IF NOT EXISTS invoices (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    date DATE NOT NULL,
    invoice_id TEXT NOT NULL,
    asin TEXT NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 0,
    item_price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    freight_cost DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(vendor, invoice_id, asin)
);

CREATE INDEX IF NOT EXISTS idx_invoices_vendor ON invoices(vendor);
CREATE INDEX IF NOT EXISTS idx_invoices_date ON invoices(date DESC);
CREATE INDEX IF NOT EXISTS idx_invoices_asin ON invoices(asin);
CREATE INDEX IF NOT EXISTS idx_invoices_invoice_id ON invoices(invoice_id);
CREATE INDEX IF NOT EXISTS idx_invoices_vendor_date ON invoices(vendor, date DESC);

-- ============================================
-- 3. ADVERTISING TABLE (Ad Performance)
-- ============================================
CREATE TABLE IF NOT EXISTS advertising (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    date DATE NOT NULL,
    asin TEXT NOT NULL,
    spend DECIMAL(10, 2) NOT NULL DEFAULT 0,
    sales DECIMAL(10, 2) NOT NULL DEFAULT 0,
    orders INTEGER NOT NULL DEFAULT 0,
    clicks INTEGER NOT NULL DEFAULT 0,
    impressions INTEGER NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(vendor, date, asin)
);

CREATE INDEX IF NOT EXISTS idx_advertising_vendor ON advertising(vendor);
CREATE INDEX IF NOT EXISTS idx_advertising_date ON advertising(date DESC);
CREATE INDEX IF NOT EXISTS idx_advertising_asin ON advertising(asin);
CREATE INDEX IF NOT EXISTS idx_advertising_vendor_date ON advertising(vendor, date DESC);

-- ============================================
-- 4. VRET & COGS TABLE (Monthly Returns/COGS)
-- ============================================
CREATE TABLE IF NOT EXISTS vret_cogs (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    month TEXT NOT NULL CHECK (month ~ '^(0[1-9]|1[0-2])$'),
    year TEXT NOT NULL CHECK (year ~ '^\d{4}$'),
    vret DECIMAL(10, 2) NOT NULL DEFAULT 0,
    cogs DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    UNIQUE(vendor, year, month)
);

CREATE INDEX IF NOT EXISTS idx_vret_cogs_vendor ON vret_cogs(vendor);
CREATE INDEX IF NOT EXISTS idx_vret_cogs_year_month ON vret_cogs(year DESC, month DESC);
CREATE INDEX IF NOT EXISTS idx_vret_cogs_vendor_year ON vret_cogs(vendor, year DESC);

-- ============================================
-- 5. AUTO-UPDATE TIMESTAMP TRIGGER
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables
DROP TRIGGER IF EXISTS update_asin_master_updated_at ON asin_master;
CREATE TRIGGER update_asin_master_updated_at
    BEFORE UPDATE ON asin_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_invoices_updated_at ON invoices;
CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_advertising_updated_at ON advertising;
CREATE TRIGGER update_advertising_updated_at
    BEFORE UPDATE ON advertising
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_vret_cogs_updated_at ON vret_cogs;
CREATE TRIGGER update_vret_cogs_updated_at
    BEFORE UPDATE ON vret_cogs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- 6. ROW LEVEL SECURITY (Optional - Enable if using auth)
-- ============================================
-- Uncomment these if you want to add authentication later

-- ALTER TABLE asin_master ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE advertising ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE vret_cogs ENABLE ROW LEVEL SECURITY;

-- For now, allow public access (no auth)
-- You can restrict this later when adding user authentication

ALTER TABLE asin_master ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public access" ON asin_master FOR ALL USING (true);

ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public access" ON invoices FOR ALL USING (true);

ALTER TABLE advertising ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public access" ON advertising FOR ALL USING (true);

ALTER TABLE vret_cogs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Allow public access" ON vret_cogs FOR ALL USING (true);

-- ============================================
-- SETUP COMPLETE!
-- ============================================
-- Next steps:
-- 1. Verify tables were created (check Tables tab in Supabase)
-- 2. Update your frontend to use Supabase SDK
-- 3. Test CRUD operations
-- ============================================
