-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- -----------------------------------------------------------------------------
-- 1. ENUMS
-- -----------------------------------------------------------------------------

CREATE TYPE role_name AS ENUM (
    'admin',
    'manager',
    'mitarbeiter',
    'kunde',
    'hq'
);

CREATE TYPE appointment_status AS ENUM (
    'reserved',
    'requested',
    'confirmed',
    'cancelled',
    'completed',
    'no_show'
);

CREATE TYPE day_of_week AS ENUM (
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
);

-- -----------------------------------------------------------------------------
-- 2. CORE TABLES
-- -----------------------------------------------------------------------------

-- Salons
CREATE TABLE salons (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    slug TEXT NOT NULL UNIQUE,
    address TEXT,
    phone TEXT,
    email TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Profiles (extends auth.users)
CREATE TABLE profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    first_name TEXT,
    last_name TEXT,
    phone TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Roles
CREATE TABLE user_roles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    salon_id UUID REFERENCES salons(id) ON DELETE CASCADE,
    role role_name NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- A user can have a role in a salon, or a global role (salon_id is null)
    UNIQUE(profile_id, salon_id, role)
);

-- Tax Rates
CREATE TABLE tax_rates (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    rate_percent NUMERIC(5, 2) NOT NULL, -- e.g. 7.70
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Customers
CREATE TABLE customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Link to registered user
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff
CREATE TABLE staff (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    profile_id UUID REFERENCES profiles(id) ON DELETE SET NULL, -- Staff must have a profile to login
    display_name TEXT NOT NULL,
    bio TEXT,
    color_code TEXT, -- For calendar display
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service Categories
CREATE TABLE service_categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Services
CREATE TABLE services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    category_id UUID NOT NULL REFERENCES service_categories(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    base_duration_minutes INTEGER NOT NULL,
    buffer_after_minutes INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Service Prices
CREATE TABLE service_prices (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    price NUMERIC(10, 2) NOT NULL,
    tax_rate_id UUID NOT NULL REFERENCES tax_rates(id),
    valid_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_to TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Service Skills (Many-to-Many)
CREATE TABLE staff_service_skills (
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE CASCADE,
    PRIMARY KEY (staff_id, service_id)
);

-- Opening Hours
CREATE TABLE opening_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    day_of_week day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Staff Working Hours
CREATE TABLE staff_working_hours (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE CASCADE,
    day_of_week day_of_week NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Booking Rules
CREATE TABLE booking_rules (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    min_lead_time_minutes INTEGER DEFAULT 60,
    max_booking_horizon_days INTEGER DEFAULT 90,
    cancellation_cutoff_hours INTEGER DEFAULT 24,
    slot_granularity_minutes INTEGER DEFAULT 15,
    deposit_required_percent INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(salon_id)
);

-- Appointments
CREATE TABLE appointments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    salon_id UUID NOT NULL REFERENCES salons(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES customers(id) ON DELETE RESTRICT,
    staff_id UUID NOT NULL REFERENCES staff(id) ON DELETE RESTRICT,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    status appointment_status NOT NULL DEFAULT 'reserved',
    reserved_until TIMESTAMPTZ, -- For temporary holds
    internal_notes TEXT,
    customer_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Appointment Services (Many-to-Many with snapshot data)
CREATE TABLE appointment_services (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    appointment_id UUID NOT NULL REFERENCES appointments(id) ON DELETE CASCADE,
    service_id UUID NOT NULL REFERENCES services(id) ON DELETE RESTRICT,
    snapshot_price NUMERIC(10, 2) NOT NULL,
    snapshot_duration_minutes INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- -----------------------------------------------------------------------------
-- 3. ROW LEVEL SECURITY (RLS)
-- -----------------------------------------------------------------------------

-- Enable RLS on all tables
ALTER TABLE salons ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE services ENABLE ROW LEVEL SECURITY;
ALTER TABLE service_prices ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_service_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE opening_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff_working_hours ENABLE ROW LEVEL SECURITY;
ALTER TABLE booking_rules ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;
ALTER TABLE appointment_services ENABLE ROW LEVEL SECURITY;
ALTER TABLE tax_rates ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is admin/manager/staff in a salon
CREATE OR REPLACE FUNCTION public.has_role_in_salon(check_salon_id UUID, check_roles role_name[])
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM user_roles
        WHERE profile_id = auth.uid()
        AND salon_id = check_salon_id
        AND role = ANY(check_roles)
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- --------------------
-- POLICIES
-- --------------------

-- SALONS: Public can view basic info. Admins can edit.
CREATE POLICY "Public can view salons" ON salons FOR SELECT USING (true);
CREATE POLICY "Admins can update their salons" ON salons FOR UPDATE USING (
    has_role_in_salon(id, ARRAY['admin'::role_name])
);

-- PROFILES: Users can view/edit their own. Staff can view all (for customer search).
CREATE POLICY "Users can view own profile" ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Staff can view all profiles" ON profiles FOR SELECT USING (
    EXISTS (SELECT 1 FROM user_roles WHERE profile_id = auth.uid() AND role IN ('admin', 'manager', 'mitarbeiter'))
);

-- USER_ROLES: Admins can view/manage roles. Users can view their own.
CREATE POLICY "Users can view own roles" ON user_roles FOR SELECT USING (profile_id = auth.uid());
CREATE POLICY "Admins can manage roles" ON user_roles FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name])
);

-- SERVICES / PRICES / OPENING HOURS / RULES: Public read, Staff write
CREATE POLICY "Public read services" ON services FOR SELECT USING (true);
CREATE POLICY "Staff manage services" ON services FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

CREATE POLICY "Public read categories" ON service_categories FOR SELECT USING (true);
CREATE POLICY "Staff manage categories" ON service_categories FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

CREATE POLICY "Public read prices" ON service_prices FOR SELECT USING (true);
CREATE POLICY "Staff manage prices" ON service_prices FOR ALL USING (
    EXISTS (SELECT 1 FROM services s WHERE s.id = service_id AND has_role_in_salon(s.salon_id, ARRAY['admin'::role_name, 'manager'::role_name]))
);

CREATE POLICY "Public read working hours" ON staff_working_hours FOR SELECT USING (true);
CREATE POLICY "Staff manage working hours" ON staff_working_hours FOR ALL USING (
    EXISTS (SELECT 1 FROM staff s WHERE s.id = staff_id AND has_role_in_salon(s.salon_id, ARRAY['admin'::role_name, 'manager'::role_name]))
);

CREATE POLICY "Public read opening hours" ON opening_hours FOR SELECT USING (true);
CREATE POLICY "Staff manage opening hours" ON opening_hours FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

CREATE POLICY "Public read booking rules" ON booking_rules FOR SELECT USING (true);
CREATE POLICY "Staff manage booking rules" ON booking_rules FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

CREATE POLICY "Public read tax rates" ON tax_rates FOR SELECT USING (true);
CREATE POLICY "Staff manage tax rates" ON tax_rates FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

-- CUSTOMERS:
-- Staff can view all customers in their salon.
-- Customers can view their own record (linked via profile_id).
CREATE POLICY "Staff view salon customers" ON customers FOR SELECT USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name, 'mitarbeiter'::role_name])
);
CREATE POLICY "Staff manage salon customers" ON customers FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name, 'mitarbeiter'::role_name])
);
CREATE POLICY "Customers view own record" ON customers FOR SELECT USING (
    profile_id = auth.uid()
);
CREATE POLICY "Customers update own record" ON customers FOR UPDATE USING (
    profile_id = auth.uid()
);

-- STAFF:
-- Public can view staff (for booking).
-- Staff can update their own bio? Or only admins? Let's say admins/managers manage staff.
CREATE POLICY "Public read staff" ON staff FOR SELECT USING (true);
CREATE POLICY "Managers manage staff" ON staff FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name])
);

-- APPOINTMENTS:
-- Staff can view/manage all in salon.
-- Customers can view/manage their own.
CREATE POLICY "Staff manage salon appointments" ON appointments FOR ALL USING (
    has_role_in_salon(salon_id, ARRAY['admin'::role_name, 'manager'::role_name, 'mitarbeiter'::role_name])
);
CREATE POLICY "Customers view own appointments" ON appointments FOR SELECT USING (
    customer_id IN (SELECT id FROM customers WHERE profile_id = auth.uid())
);
-- Customers can create appointments (insert)
CREATE POLICY "Customers create appointments" ON appointments FOR INSERT WITH CHECK (
    customer_id IN (SELECT id FROM customers WHERE profile_id = auth.uid())
);
-- Customers can cancel (update status) - logic usually handled in API/Action, but RLS allows update if own
CREATE POLICY "Customers update own appointments" ON appointments FOR UPDATE USING (
    customer_id IN (SELECT id FROM customers WHERE profile_id = auth.uid())
);

-- APPOINTMENT SERVICES
CREATE POLICY "Staff manage appointment services" ON appointment_services FOR ALL USING (
    EXISTS (SELECT 1 FROM appointments a WHERE a.id = appointment_id AND has_role_in_salon(a.salon_id, ARRAY['admin'::role_name, 'manager'::role_name, 'mitarbeiter'::role_name]))
);
CREATE POLICY "Customers view own appointment services" ON appointment_services FOR SELECT USING (
    EXISTS (SELECT 1 FROM appointments a WHERE a.id = appointment_id AND a.customer_id IN (SELECT id FROM customers WHERE profile_id = auth.uid()))
);
CREATE POLICY "Customers insert appointment services" ON appointment_services FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM appointments a WHERE a.id = appointment_id AND a.customer_id IN (SELECT id FROM customers WHERE profile_id = auth.uid()))
);


-- -----------------------------------------------------------------------------
-- 4. TRIGGERS
-- -----------------------------------------------------------------------------

-- Automatically create a profile when a new user signs up via Supabase Auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, first_name, last_name)
    VALUES (
        new.id,
        new.email,
        new.raw_user_meta_data->>'first_name',
        new.raw_user_meta_data->>'last_name'
    );
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
