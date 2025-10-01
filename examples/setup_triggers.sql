-- Example: Setting up PostgreSQL NOTIFY triggers for real-time updates
-- This example shows how to create triggers that will send notifications to the WebSocket server

-- 1. Create a generic notify function that can be reused for any table
CREATE OR REPLACE FUNCTION notify_db_changes()
RETURNS trigger AS $$
DECLARE
  payload JSON;
BEGIN
  -- Build the payload with operation type and data
  IF (TG_OP = 'DELETE') THEN
    payload = json_build_object(
      'table', TG_TABLE_NAME,
      'operation', TG_OP,
      'old_data', row_to_json(OLD)
    );
  ELSIF (TG_OP = 'UPDATE') THEN
    payload = json_build_object(
      'table', TG_TABLE_NAME,
      'operation', TG_OP,
      'old_data', row_to_json(OLD),
      'new_data', row_to_json(NEW)
    );
  ELSE -- INSERT
    payload = json_build_object(
      'table', TG_TABLE_NAME,
      'operation', TG_OP,
      'new_data', row_to_json(NEW)
    );
  END IF;

  -- Send notification on the 'db_changes' channel
  PERFORM pg_notify('db_changes', payload::text);
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 2. Example: Create a sample table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- 3. Create trigger for the users table
DROP TRIGGER IF EXISTS users_notify_trigger ON users;
CREATE TRIGGER users_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW
  EXECUTE FUNCTION notify_db_changes();

-- 4. Example: Create another table with its own trigger
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id),
  title VARCHAR(200) NOT NULL,
  content TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

DROP TRIGGER IF EXISTS posts_notify_trigger ON posts;
CREATE TRIGGER posts_notify_trigger
  AFTER INSERT OR UPDATE OR DELETE ON posts
  FOR EACH ROW
  EXECUTE FUNCTION notify_db_changes();

-- 5. Optional: Create a custom channel for specific table notifications
CREATE OR REPLACE FUNCTION notify_table_updates()
RETURNS trigger AS $$
DECLARE
  payload JSON;
  channel_name TEXT;
BEGIN
  -- Use table-specific channel
  channel_name := TG_TABLE_NAME || '_updates';
  
  IF (TG_OP = 'DELETE') THEN
    payload = json_build_object(
      'operation', TG_OP,
      'data', row_to_json(OLD)
    );
  ELSIF (TG_OP = 'UPDATE') THEN
    payload = json_build_object(
      'operation', TG_OP,
      'old', row_to_json(OLD),
      'new', row_to_json(NEW)
    );
  ELSE -- INSERT
    payload = json_build_object(
      'operation', TG_OP,
      'data', row_to_json(NEW)
    );
  END IF;

  -- Send notification on table-specific channel
  PERFORM pg_notify(channel_name, payload::text);
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Test the setup (uncomment to test):
-- INSERT INTO users (name, email) VALUES ('Test User', 'test@example.com');
-- UPDATE users SET name = 'Updated User' WHERE email = 'test@example.com';
-- DELETE FROM users WHERE email = 'test@example.com';
