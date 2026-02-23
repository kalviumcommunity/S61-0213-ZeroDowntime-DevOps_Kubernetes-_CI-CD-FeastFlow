import { Pool } from 'pg';
import dotenv from 'dotenv';

dotenv.config();

const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME || 'feastflow',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD,
});

async function fixCartTables() {
  const client = await pool.connect();
  
  try {
    console.log(' Fixing cart tables to work with string IDs...');
    
    // Drop existing tables
    await client.query('DROP TABLE IF EXISTS cart_items CASCADE;');
    await client.query('DROP TABLE IF EXISTS cart CASCADE;');
    console.log(' Old cart tables dropped');

    // Create cart table with VARCHAR restaurant_id (no FK constraint)
    await client.query(`
      CREATE TABLE cart (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        user_id UUID REFERENCES users(id) ON DELETE CASCADE,
        restaurant_id VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(user_id)
      );
    `);
    console.log(' Cart table created with VARCHAR restaurant_id');

    // Create cart_items table
    await client.query(`
      CREATE TABLE cart_items (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        cart_id UUID REFERENCES cart(id) ON DELETE CASCADE,
        menu_item_id VARCHAR(50) NOT NULL,
        menu_item_name VARCHAR(255) NOT NULL,
        menu_item_price DECIMAL(10,2) NOT NULL,
        menu_item_description TEXT,
        menu_item_category VARCHAR(100),
        restaurant_id VARCHAR(50) NOT NULL,
        restaurant_name VARCHAR(255) NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 1,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        UNIQUE(cart_id, menu_item_id)
      );
    `);
    console.log(' Cart_items table created');

    // Create triggers for cart tables
    await client.query(`
      DROP TRIGGER IF EXISTS update_cart_updated_at ON cart;
      CREATE TRIGGER update_cart_updated_at BEFORE UPDATE ON cart
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log(' Cart trigger created');

    await client.query(`
      DROP TRIGGER IF EXISTS update_cart_items_updated_at ON cart_items;
      CREATE TRIGGER update_cart_items_updated_at BEFORE UPDATE ON cart_items
        FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
    `);
    console.log(' Cart_items trigger created');

    console.log(' Cart tables fixed successfully!');
    
  } catch (error) {
    console.error(' Failed to fix cart tables:', error);
    throw error;
  } finally {
    client.release();
    await pool.end();
  }
}

fixCartTables().catch(console.error);
