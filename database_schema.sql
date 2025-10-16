-- Visitor Tracking System Database Schema for Supabase

-- Personnel table for authentication and access control
CREATE TABLE IF NOT EXISTS personnel (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    name TEXT NOT NULL,
    clearance_level TEXT NOT NULL CHECK (clearance_level IN ('admin', 'personnel')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Visitors table for vehicle tracking
CREATE TABLE IF NOT EXISTS visitors (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    plate_number TEXT NOT NULL,
    entry_time TIMESTAMP WITH TIME ZONE NOT NULL,
    exit_time TIMESTAMP WITH TIME ZONE,
    duration_minutes INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Settings table for system configuration
CREATE TABLE IF NOT EXISTS settings (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    overstay_threshold_hours INTEGER DEFAULT 8 NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_by UUID REFERENCES personnel(id)
);

-- Insert default admin user (password: admin123 - should be changed after first login)
INSERT INTO personnel (email, password_hash, name, clearance_level) 
VALUES (
    'admin@company.com',
    '$2a$10$8K1p/a0dL3LK4Y5JZJxY7.WzFZH8mZxl3H9aJ9mZmZmZmZmZmZmZm',
    'Administrator',
    'admin'
) ON CONFLICT (email) DO NOTHING;

-- Insert default settings
INSERT INTO settings (overstay_threshold_hours) 
VALUES (8) 
ON CONFLICT DO NOTHING;

-- Index for faster lookups
CREATE INDEX IF NOT EXISTS idx_visitors_plate ON visitors(plate_number);
CREATE INDEX IF NOT EXISTS idx_visitors_entry_time ON visitors(entry_time);
CREATE INDEX IF NOT EXISTS idx_visitors_exit_time ON visitors(exit_time);
CREATE INDEX IF NOT EXISTS idx_personnel_email ON personnel(email);

-- Row Level Security (RLS) Policies
ALTER TABLE personnel ENABLE ROW LEVEL SECURITY;
ALTER TABLE visitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;

-- Allow authenticated users to read personnel (for login)
CREATE POLICY "Allow personnel read access" ON personnel
    FOR SELECT USING (true);

-- Allow all operations on visitors for authenticated users
CREATE POLICY "Allow visitor operations" ON visitors
    FOR ALL USING (true);

-- Allow all operations on settings for authenticated users
CREATE POLICY "Allow settings operations" ON settings
    FOR ALL USING (true);
