-- Dummy user data for testing
-- This file contains test user accounts for development purposes

-- Insert a test user
INSERT INTO public.users (id, email, created_at)
VALUES 
    ('00000000-0000-0000-0000-000000000001'::UUID, 'test@example.com', NOW()),
    ('00000000-0000-0000-0000-000000000002'::UUID, 'demo@example.com', NOW())
ON CONFLICT (email) DO NOTHING;
