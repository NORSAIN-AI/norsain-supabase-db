-- Test RLS policy for users select
-- This test verifies that users can only select their own data

BEGIN;

-- Create a test user
INSERT INTO auth.users (id, email)
VALUES 
    ('11111111-1111-1111-1111-111111111111'::UUID, 'test_user@example.com')
ON CONFLICT DO NOTHING;

-- Insert test data into users table
INSERT INTO public.users (id, email, created_at)
VALUES 
    ('11111111-1111-1111-1111-111111111111'::UUID, 'test_user@example.com', NOW()),
    ('22222222-2222-2222-2222-222222222222'::UUID, 'other_user@example.com', NOW())
ON CONFLICT (email) DO NOTHING;

-- Set the current user context
SET LOCAL auth.uid TO '11111111-1111-1111-1111-111111111111';

-- Test: User should be able to select their own data
DO $$
DECLARE
    user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO user_count
    FROM public.users
    WHERE id = '11111111-1111-1111-1111-111111111111'::UUID;
    
    IF user_count != 1 THEN
        RAISE EXCEPTION 'Test failed: User should be able to see their own data';
    END IF;
    
    RAISE NOTICE 'Test passed: User can select their own data';
END $$;

-- Test: User should NOT be able to see other users' data
DO $$
DECLARE
    other_user_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO other_user_count
    FROM public.users
    WHERE id = '22222222-2222-2222-2222-222222222222'::UUID;
    
    IF other_user_count != 0 THEN
        RAISE EXCEPTION 'Test failed: User should not be able to see other users data';
    END IF;
    
    RAISE NOTICE 'Test passed: User cannot select other users data';
END $$;

ROLLBACK;
