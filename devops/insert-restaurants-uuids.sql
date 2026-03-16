-- Insert restaurants with correct UUIDs to match frontend
TRUNCATE TABLE restaurants RESTART IDENTITY CASCADE;

INSERT INTO restaurants (id, name, cuisine, description, address, phone, rating, delivery_time, delivery_fee, image_url, is_active)
VALUES
  ('7e1e2b2a-1c2d-4e3f-8a9b-1b2c3d4e5f61', 'Sakura Zen', 'Japanese', 'Japanese cuisine', '123 Sakura St', '123-456-7890', 4.8, '25-35 min', 2.99, 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop', true),
  ('2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c72', 'Napoli Fire', 'Italian', 'Italian cuisine', '456 Napoli Ave', '234-567-8901', 4.6, '30-40 min', 1.99, 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop', true),
  ('3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e83', 'Smash Stack', 'American', 'American cuisine', '789 Smash Rd', '345-678-9012', 4.5, '20-30 min', 0.00, 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop', true),
  ('4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f94', 'Spice Route', 'Indian', 'Indian cuisine', '321 Spice Blvd', '456-789-0123', 4.7, '35-45 min', 3.49, 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&h=600&fit=crop', true),
  ('5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a05', 'El Fuego', 'Mexican', 'Mexican cuisine', '654 Fuego Ln', '567-890-1234', 4.4, '25-35 min', 1.49, 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&h=600&fit=crop', true);
