-- Seed data for SCHNITTWERK

-- 1. Create the Salon
INSERT INTO salons (id, name, slug, address, email)
VALUES (
    'd06d9842-c00d-4b7a-9625-520203942001',
    'SCHNITTWERK by Vanessa Carosella',
    'schnittwerk-stgallen',
    'Rorschacherstrasse 152, 9000 St. Gallen',
    'info@schnittwerk.ch'
) ON CONFLICT DO NOTHING;

-- 2. Tax Rates
INSERT INTO tax_rates (id, salon_id, name, rate_percent)
VALUES
    ('t16d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'Standard', 8.1),
    ('t26d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'Reduziert', 2.6)
ON CONFLICT DO NOTHING;

-- 3. Booking Rules
INSERT INTO booking_rules (salon_id, min_lead_time_minutes, max_booking_horizon_days)
VALUES (
    'd06d9842-c00d-4b7a-9625-520203942001',
    60,
    90
) ON CONFLICT DO NOTHING;

-- 4. Service Categories
INSERT INTO service_categories (id, salon_id, name, sort_order)
VALUES
    ('c16d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'Damen', 1),
    ('c26d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'Herren', 2),
    ('c36d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'Farbe', 3)
ON CONFLICT DO NOTHING;

-- 5. Services
INSERT INTO services (id, salon_id, category_id, name, base_duration_minutes)
VALUES
    ('s16d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'c16d9842-c00d-4b7a-9625-520203942001', 'Waschen, Schneiden, Föhnen', 60),
    ('s26d9842-c00d-4b7a-9625-520203942001', 'd06d9842-c00d-4b7a-9625-520203942001', 'c26d9842-c00d-4b7a-9625-520203942001', 'Herrenhaarschnitt', 30)
ON CONFLICT DO NOTHING;

-- 6. Service Prices
INSERT INTO service_prices (id, service_id, price, tax_rate_id)
VALUES
    (uuid_generate_v4(), 's16d9842-c00d-4b7a-9625-520203942001', 95.00, 't16d9842-c00d-4b7a-9625-520203942001'),
    (uuid_generate_v4(), 's26d9842-c00d-4b7a-9625-520203942001', 55.00, 't16d9842-c00d-4b7a-9625-520203942001')
ON CONFLICT DO NOTHING;

-- 7. Opening Hours
INSERT INTO opening_hours (salon_id, day_of_week, start_time, end_time)
VALUES
    ('d06d9842-c00d-4b7a-9625-520203942001', 'tuesday', '09:00', '18:30'),
    ('d06d9842-c00d-4b7a-9625-520203942001', 'wednesday', '09:00', '18:30'),
    ('d06d9842-c00d-4b7a-9625-520203942001', 'thursday', '09:00', '18:30'),
    ('d06d9842-c00d-4b7a-9625-520203942001', 'friday', '09:00', '18:30'),
    ('d06d9842-c00d-4b7a-9625-520203942001', 'saturday', '08:00', '14:00')
ON CONFLICT DO NOTHING;
