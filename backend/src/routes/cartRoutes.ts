import express from 'express';
import {
  getCart,
  addToCart,
  updateCartItem,
  removeFromCart,
  clearCart,
} from '../controllers/cartController';
import { protect } from '../middleware/auth';

const router = express.Router();

// All cart routes require authentication
router.use(protect);

// Get user's cart
router.get('/', getCart);

// Add item to cart
router.post('/items', addToCart);

// Update cart item quantity
router.put('/items/:itemId', updateCartItem);

// Remove item from cart
router.delete('/items/:itemId', removeFromCart);

// Clear cart
router.delete('/', clearCart);

export default router;
