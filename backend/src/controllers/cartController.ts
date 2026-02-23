import { Response } from 'express';
import { AuthRequest } from '../types';
import pool from '../database/db';

// Get user's cart
export const getCart = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    // Get or create cart
    let cartResult = await pool.query(
      'SELECT * FROM cart WHERE user_id = $1',
      [userId]
    );

    if (cartResult.rows.length === 0) {
      // Create new cart
      cartResult = await pool.query(
        'INSERT INTO cart (user_id) VALUES ($1) RETURNING *',
        [userId]
      );
    }

    const cartId = cartResult.rows[0].id;

    // Get cart items
    const itemsResult = await pool.query(
      'SELECT * FROM cart_items WHERE cart_id = $1 ORDER BY created_at DESC',
      [cartId]
    );

    res.status(200).json({
      success: true,
      data: {
        cart: cartResult.rows[0],
        items: itemsResult.rows,
      },
    });
  } catch (error) {
    console.error('Get cart error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Add item to cart
export const addToCart = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const {
      menuItemId,
      menuItemName,
      menuItemPrice,
      menuItemDescription,
      menuItemCategory,
      restaurantId,
      restaurantName,
      quantity = 1,
    } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    if (!menuItemId || !menuItemName || !menuItemPrice || !restaurantId || !restaurantName) {
      return res.status(400).json({ success: false, message: 'Missing required fields' });
    }

    // Get or create cart
    let cartResult = await pool.query(
      'SELECT * FROM cart WHERE user_id = $1',
      [userId]
    );

    let cartId: string;
    let currentRestaurantId: string | null = null;

    if (cartResult.rows.length === 0) {
      // Create new cart
      cartResult = await pool.query(
        'INSERT INTO cart (user_id, restaurant_id) VALUES ($1, $2) RETURNING *',
        [userId, restaurantId]
      );
      cartId = cartResult.rows[0].id;
    } else {
      cartId = cartResult.rows[0].id;
      currentRestaurantId = cartResult.rows[0].restaurant_id;

      // Check if adding from different restaurant
      if (currentRestaurantId && currentRestaurantId !== restaurantId) {
        // Clear cart and update restaurant
        await pool.query('DELETE FROM cart_items WHERE cart_id = $1', [cartId]);
        await pool.query('UPDATE cart SET restaurant_id = $1 WHERE id = $2', [restaurantId, cartId]);
      } else if (!currentRestaurantId) {
        // Update restaurant_id if not set
        await pool.query('UPDATE cart SET restaurant_id = $1 WHERE id = $2', [restaurantId, cartId]);
      }
    }

    // Check if item already exists
    const existingItem = await pool.query(
      'SELECT * FROM cart_items WHERE cart_id = $1 AND menu_item_id = $2',
      [cartId, menuItemId]
    );

    let result;
    if (existingItem.rows.length > 0) {
      // Update quantity
      result = await pool.query(
        'UPDATE cart_items SET quantity = quantity + $1, updated_at = CURRENT_TIMESTAMP WHERE cart_id = $2 AND menu_item_id = $3 RETURNING *',
        [quantity, cartId, menuItemId]
      );
    } else {
      // Add new item
      result = await pool.query(
        `INSERT INTO cart_items 
        (cart_id, menu_item_id, menu_item_name, menu_item_price, menu_item_description, menu_item_category, restaurant_id, restaurant_name, quantity) 
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9) 
        RETURNING *`,
        [cartId, menuItemId, menuItemName, menuItemPrice, menuItemDescription, menuItemCategory, restaurantId, restaurantName, quantity]
      );
    }

    res.status(200).json({
      success: true,
      message: 'Item added to cart',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Add to cart error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Update cart item quantity
export const updateCartItem = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const { itemId } = req.params;
    const { quantity } = req.body;

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    if (quantity < 0) {
      return res.status(400).json({ success: false, message: 'Invalid quantity' });
    }

    // Get user's cart
    const cartResult = await pool.query(
      'SELECT id FROM cart WHERE user_id = $1',
      [userId]
    );

    if (cartResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Cart not found' });
    }

    const cartId = cartResult.rows[0].id;

    if (quantity === 0) {
      // Remove item
      await pool.query(
        'DELETE FROM cart_items WHERE cart_id = $1 AND menu_item_id = $2',
        [cartId, itemId]
      );

      return res.status(200).json({
        success: true,
        message: 'Item removed from cart',
      });
    }

    // Update quantity
    const result = await pool.query(
      'UPDATE cart_items SET quantity = $1, updated_at = CURRENT_TIMESTAMP WHERE cart_id = $2 AND menu_item_id = $3 RETURNING *',
      [quantity, cartId, itemId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Item not found in cart' });
    }

    res.status(200).json({
      success: true,
      message: 'Cart updated',
      data: result.rows[0],
    });
  } catch (error) {
    console.error('Update cart error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Remove item from cart
export const removeFromCart = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;
    const { itemId } = req.params;

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    // Get user's cart
    const cartResult = await pool.query(
      'SELECT id FROM cart WHERE user_id = $1',
      [userId]
    );

    if (cartResult.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Cart not found' });
    }

    const cartId = cartResult.rows[0].id;

    // Remove item
    const result = await pool.query(
      'DELETE FROM cart_items WHERE cart_id = $1 AND menu_item_id = $2 RETURNING *',
      [cartId, itemId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Item not found in cart' });
    }

    res.status(200).json({
      success: true,
      message: 'Item removed from cart',
    });
  } catch (error) {
    console.error('Remove from cart error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};

// Clear cart
export const clearCart = async (req: AuthRequest, res: Response) => {
  try {
    const userId = req.user?.id;

    if (!userId) {
      return res.status(401).json({ success: false, message: 'Unauthorized' });
    }

    // Get user's cart
    const cartResult = await pool.query(
      'SELECT id FROM cart WHERE user_id = $1',
      [userId]
    );

    if (cartResult.rows.length === 0) {
      return res.status(200).json({
        success: true,
        message: 'Cart already empty',
      });
    }

    const cartId = cartResult.rows[0].id;

    // Clear all items
    await pool.query('DELETE FROM cart_items WHERE cart_id = $1', [cartId]);
    await pool.query('UPDATE cart SET restaurant_id = NULL WHERE id = $1', [cartId]);

    res.status(200).json({
      success: true,
      message: 'Cart cleared',
    });
  } catch (error) {
    console.error('Clear cart error:', error);
    res.status(500).json({ success: false, message: 'Server error' });
  }
};
