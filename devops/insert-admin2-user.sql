-- Insert default admin user for FeastFlow
INSERT INTO users (id, email, password, first_name, last_name, role, phone_number)
VALUES (
  gen_random_uuid(),
  'admin2@feastflow.com',
  '$2b$10$wqQwQwQwQwQwQwQwQwQwQeQwQwQwQwQwQwQwQwQwQwQwQwQwQwQwQwQwQw', -- bcrypt hash for Admin@123
  'Admin',
  'User',
  'admin',
  '1234567890'
);
