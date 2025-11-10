# Supabase Database Schema for Amazon P&L Dashboard

This document outlines the complete database schema for migrating the Amazon P&L Dashboard from localStorage to Supabase PostgreSQL.

## Overview

The application tracks profit & loss data for multiple vendors across 4 main data types:
1. ASIN Master (Product pricing)
2. Invoices (Sales transactions)
3. Advertising (Ad spend and performance)
4. VRET & COGS (Vendor returns and cost of goods sold)

## Vendors

Three vendors are currently supported:
- `etrade`
- `retailez`
- `clicktech`

---

## Table: `asin_master`

**Purpose:** Store ASIN (Amazon Standard Identification Number) and pricing information for products.

```sql
CREATE TABLE asin_master (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    asin TEXT NOT NULL,
    price DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure unique ASIN per vendor
    UNIQUE(vendor, asin)
);

-- Indexes for performance
CREATE INDEX idx_asin_master_vendor ON asin_master(vendor);
CREATE INDEX idx_asin_master_asin ON asin_master(asin);
CREATE INDEX idx_asin_master_created_at ON asin_master(created_at DESC);
```

**Columns:**
- `id`: Unique identifier (auto-increment)
- `vendor`: Vendor name (etrade, retailez, clicktech)
- `asin`: Amazon product identifier
- `price`: Product cost price
- `created_at`: Record creation timestamp
- `updated_at`: Last update timestamp

**Current Data Source:** `state.asinData[vendor]`

**Google Sheets Tab:** `ASIN_Master`

---

## Table: `invoices`

**Purpose:** Store sales invoice data including quantities, prices, and freight costs.

```sql
CREATE TABLE invoices (
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

    -- Ensure unique invoice per vendor
    UNIQUE(vendor, invoice_id, asin)
);

-- Indexes for performance
CREATE INDEX idx_invoices_vendor ON invoices(vendor);
CREATE INDEX idx_invoices_date ON invoices(date DESC);
CREATE INDEX idx_invoices_asin ON invoices(asin);
CREATE INDEX idx_invoices_invoice_id ON invoices(invoice_id);
CREATE INDEX idx_invoices_vendor_date ON invoices(vendor, date DESC);
```

**Columns:**
- `id`: Unique identifier (auto-increment)
- `vendor`: Vendor name
- `date`: Invoice date
- `invoice_id`: Invoice number
- `asin`: Product ASIN
- `quantity`: Number of units sold
- `item_price`: Selling price per unit
- `freight_cost`: Shipping/freight cost
- `created_at`: Record creation timestamp
- `updated_at`: Last update timestamp

**Current Data Source:** `state.savedInvoices[vendor]`

**Google Sheets Tab:** `Invoices`

---

## Table: `advertising`

**Purpose:** Store advertising campaign data including spend, sales, and performance metrics.

```sql
CREATE TABLE advertising (
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

    -- Ensure unique advertising record per vendor/date/asin
    UNIQUE(vendor, date, asin)
);

-- Indexes for performance
CREATE INDEX idx_advertising_vendor ON advertising(vendor);
CREATE INDEX idx_advertising_date ON advertising(date DESC);
CREATE INDEX idx_advertising_asin ON advertising(asin);
CREATE INDEX idx_advertising_vendor_date ON advertising(vendor, date DESC);
```

**Columns:**
- `id`: Unique identifier (auto-increment)
- `vendor`: Vendor name
- `date`: Advertising date
- `asin`: Product ASIN
- `spend`: Advertising spend amount
- `sales`: Sales generated from ads
- `orders`: Number of orders
- `clicks`: Number of ad clicks
- `impressions`: Number of ad impressions
- `created_at`: Record creation timestamp
- `updated_at`: Last update timestamp

**Current Data Source:** `state.advertisingData[vendor]`

**Google Sheets Tab:** `Advertising`

---

## Table: `vret_cogs`

**Purpose:** Store monthly VRET (Vendor Returns) and COGS (Cost of Goods Sold) data.

```sql
CREATE TABLE vret_cogs (
    id BIGSERIAL PRIMARY KEY,
    vendor TEXT NOT NULL CHECK (vendor IN ('etrade', 'retailez', 'clicktech')),
    month TEXT NOT NULL CHECK (month ~ '^(0[1-9]|1[0-2])$'), -- 01-12 format
    year TEXT NOT NULL CHECK (year ~ '^\d{4}$'), -- YYYY format
    vret DECIMAL(10, 2) NOT NULL DEFAULT 0,
    cogs DECIMAL(10, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure unique record per vendor/month/year
    UNIQUE(vendor, year, month)
);

-- Indexes for performance
CREATE INDEX idx_vret_cogs_vendor ON vret_cogs(vendor);
CREATE INDEX idx_vret_cogs_year_month ON vret_cogs(year DESC, month DESC);
CREATE INDEX idx_vret_cogs_vendor_year ON vret_cogs(vendor, year DESC);
```

**Columns:**
- `id`: Unique identifier (auto-increment)
- `vendor`: Vendor name
- `month`: Month (01-12, 2-digit format)
- `year`: Year (YYYY format)
- `vret`: Vendor return amount
- `cogs`: Cost of goods sold discount
- `created_at`: Record creation timestamp
- `updated_at`: Last update timestamp

**Current Data Source:** `state.savedVretCogs[vendor]`

**Google Sheets Tab:** `VRET_COGS`

---

## Additional Tables (Optional)

### Table: `users` (For Multi-User Support)

```sql
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Table: `vendors` (For Vendor Management)

```sql
CREATE TABLE vendors (
    id BIGSERIAL PRIMARY KEY,
    code TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default vendors
INSERT INTO vendors (code, name) VALUES
    ('etrade', 'E-Trade'),
    ('retailez', 'Retailez'),
    ('clicktech', 'ClickTech');
```

---

## Row Level Security (RLS) Policies

Enable RLS for multi-user scenarios:

```sql
-- Enable RLS on all tables
ALTER TABLE asin_master ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE advertising ENABLE ROW LEVEL SECURITY;
ALTER TABLE vret_cogs ENABLE ROW LEVEL SECURITY;

-- Example policy for public access (adjust based on your auth needs)
CREATE POLICY "Allow public read access" ON asin_master
    FOR SELECT USING (true);

CREATE POLICY "Allow public insert" ON asin_master
    FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow public update" ON asin_master
    FOR UPDATE USING (true);

-- Repeat for other tables
```

---

## Triggers for Updated Timestamps

Automatically update `updated_at` timestamps:

```sql
-- Create function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to all tables
CREATE TRIGGER update_asin_master_updated_at
    BEFORE UPDATE ON asin_master
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_invoices_updated_at
    BEFORE UPDATE ON invoices
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_advertising_updated_at
    BEFORE UPDATE ON advertising
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_vret_cogs_updated_at
    BEFORE UPDATE ON vret_cogs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Useful Queries

### Get Total Revenue by Vendor
```sql
SELECT
    vendor,
    SUM(quantity * item_price) as total_revenue,
    SUM(freight_cost) as total_freight
FROM invoices
GROUP BY vendor
ORDER BY total_revenue DESC;
```

### Get Advertising ROAS (Return on Ad Spend) by Vendor
```sql
SELECT
    vendor,
    SUM(spend) as total_spend,
    SUM(sales) as total_sales,
    CASE
        WHEN SUM(spend) > 0 THEN ROUND((SUM(sales) / SUM(spend))::numeric, 2)
        ELSE 0
    END as roas
FROM advertising
GROUP BY vendor
ORDER BY roas DESC;
```

### Get Monthly P&L Summary
```sql
SELECT
    i.vendor,
    DATE_TRUNC('month', i.date) as month,
    SUM(i.quantity * i.item_price) as revenue,
    SUM(i.quantity * a.price) as cogs,
    SUM(i.freight_cost) as freight,
    SUM(ad.spend) as ad_spend,
    SUM(i.quantity * i.item_price) - SUM(i.quantity * a.price) - SUM(i.freight_cost) - SUM(ad.spend) as net_profit
FROM invoices i
LEFT JOIN asin_master a ON i.vendor = a.vendor AND i.asin = a.asin
LEFT JOIN advertising ad ON i.vendor = ad.vendor AND i.date = ad.date AND i.asin = ad.asin
GROUP BY i.vendor, DATE_TRUNC('month', i.date)
ORDER BY month DESC, i.vendor;
```

---

## Migration Checklist

- [ ] Create Supabase account
- [ ] Create new project
- [ ] Run table creation scripts
- [ ] Set up RLS policies (if using auth)
- [ ] Add indexes for performance
- [ ] Set up triggers for timestamps
- [ ] Get Supabase URL and API keys
- [ ] Update frontend code to use Supabase SDK
- [ ] Test CRUD operations
- [ ] Migrate existing localStorage data
- [ ] Test Google Sheets sync compatibility
- [ ] Deploy and test

---

## Current vs Future Architecture

### Current (localStorage):
```
Browser localStorage (5-10MB limit)
├── pnl_data (all app state)
└── googleSheetsConfig
```

### Future (Supabase):
```
Supabase PostgreSQL (Unlimited storage)
├── asin_master table
├── invoices table
├── advertising table
└── vret_cogs table

+ Google Sheets (Import/Export)
+ Real-time sync
+ Multi-device access
+ Better performance
```

---

## Next Steps

1. Review this schema
2. Create Supabase account if you haven't already
3. Run the SQL scripts in Supabase SQL Editor
4. Share your Supabase project URL and API keys
5. I'll update the frontend to use Supabase instead of localStorage
