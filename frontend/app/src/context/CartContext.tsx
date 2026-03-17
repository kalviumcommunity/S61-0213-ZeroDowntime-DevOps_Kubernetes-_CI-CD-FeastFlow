'use client';

import { createContext, useContext, useState, useEffect, useCallback, ReactNode } from 'react';
import { CartItem, MenuItem, Restaurant } from '@/types';
import { useAuth } from './AuthContext';


interface CartContextType {
  cart: CartItem[];
  addToCart: (item: MenuItem, restaurant: Restaurant) => void;
  removeFromCart: (itemId: string) => void;
  updateQuantity: (itemId: string, quantity: number) => void;
  clearCart: () => void;
  getTotal: () => number;
  isCartOpen: boolean;
  setIsCartOpen: (open: boolean) => void;
  createOrder: () => Promise<void>;
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: ReactNode }) {
    // ...existing code...
    // (move loadCart below user and API_URL declarations)
  const { user } = useAuth();
  const [cart, setCart] = useState<CartItem[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

  // Load cart from backend and update state, with debug logging
  const loadCart = useCallback(async () => {
    const token = localStorage.getItem('token');
    if (!token || !user) {
      setCart([]);
      console.warn('[CartContext] No token or user, cart cleared.');
      return;
    }
    try {
      const response = await fetch(`${API_URL}/cart`, {
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        credentials: 'include',
      });
      if (response.ok) {
        const data = await response.json();
        setCart(data.cart || []);
        console.log('[CartContext] Cart loaded from backend:', data.cart);
      } else {
        setCart([]);
        const errMsg = `[CartContext] Failed to load cart: ${response.status} ${response.statusText}`;
        console.error(errMsg);
        alert('Failed to load cart. Please try again.');
      }
    } catch (error) {
      console.error('[CartContext] Error loading cart from backend:', error);
      setCart([]);
      alert('Error loading cart. Please check your connection.');
    }
  }, [API_URL, user]);

  // Simulate order creation (frontend only)
  const createOrder = async () => {

    if (!user || cart.length === 0) return;
    const orders = JSON.parse(localStorage.getItem('orders') || '[]');
    const newOrder = {
      id: Date.now().toString(),
      restaurantName: cart[0].restaurant.name,
      items: cart.map(item => ({
        name: item.menuItem.name,
        quantity: item.quantity,
        price: item.menuItem.price
      })),
      total: getTotal(),
      status: 'pending',
      createdAt: new Date().toISOString(),
      deliveryAddress: user.address || 'N/A',
    };
    localStorage.setItem('orders', JSON.stringify([newOrder, ...orders]));
    setCart([]);
  };

  // Load cart from backend when API_URL changes
  useEffect(() => {
    const loadCart = async () => {
      try {
        // ...your cart loading logic here...
      } catch (error) {
        console.error('Error loading cart from backend:', error);
      }
    };
    // Optionally call loadCart here if needed
  }, [API_URL]);

  // Load cart from backend when user logs in
  useEffect(() => {
    if (user) {
      // Load cart data from backend when auth context becomes available.
      const timeoutId = window.setTimeout(() => {
        void loadCart();
      }, 0);
      return () => window.clearTimeout(timeoutId);
    }

    const timeoutId = window.setTimeout(() => {
      setCart([]);
    }, 0);

    return () => window.clearTimeout(timeoutId);
  }, [user, loadCart]);

  const addToCart = async (menuItem: MenuItem, restaurant: Restaurant) => {
    const token = localStorage.getItem('token');

    if (!token || !user) {
      alert('Please log in to add items to cart');
      console.warn('[CartContext] Tried to add to cart without user or token.');
      return;
    }

    try {
      const response = await fetch(`${API_URL}/cart/items`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        credentials: 'include',
        body: JSON.stringify({
          menuItemId: menuItem.id,
          menuItemName: menuItem.name,
          menuItemPrice: menuItem.price,
          menuItemDescription: menuItem.description,
          menuItemCategory: menuItem.category,
          restaurantId: restaurant.id,
          restaurantName: restaurant.name,
          quantity: 1,
        }),
      });

      if (response.ok) {
        // Reload cart from backend
        await loadCart();
        setIsCartOpen(true);
        console.log('[CartContext] Item added to cart:', menuItem.name);
      } else {
        const data = await response.json();
        const errMsg = data.message || 'Failed to add item to cart';
        alert(errMsg);
        console.error('[CartContext] Failed to add item to cart:', errMsg);
      }
    } catch (error) {
      console.error('[CartContext] Error adding to cart:', error);
      alert('Failed to add item to cart. Please try again.');
    }
  };

  const removeFromCart = async (itemId: string) => {
    const token = localStorage.getItem('token');

    if (!token || !user) {
      return;
    }

    try {
      const response = await fetch(`${API_URL}/cart/items/${itemId}`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        credentials: 'include',
      });

      if (response.ok) {
        // Reload cart from backend
        await loadCart();
      }
    } catch (error) {
      console.error('Error removing from cart:', error);
    }
  };

  const updateQuantity = async (itemId: string, quantity: number) => {
    if (quantity === 0) {
      await removeFromCart(itemId);
      return;
    }

    const token = localStorage.getItem('token');

    if (!token || !user) {
      return;
    }

    try {
      const response = await fetch(`${API_URL}/cart/items/${itemId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${token}`,
        },
        credentials: 'include',
        body: JSON.stringify({ quantity }),
      });

      if (response.ok) {
        // Reload cart from backend
        await loadCart();
      }
    } catch (error) {
      console.error('Error updating cart:', error);
    }
  };

  const clearCart = async () => {
    const token = localStorage.getItem('token');

    if (!token || !user) {
      setCart([]);
      setIsCartOpen(false);
      return;
    }

    try {
      const response = await fetch(`${API_URL}/cart`, {
        method: 'DELETE',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        credentials: 'include',
      });

      if (response.ok) {
        setCart([]);
        setIsCartOpen(false);
      }
    } catch (error) {
      console.error('Error clearing cart:', error);
    }
  };

  const getTotal = () => {
    return cart.reduce((total, item) => total + item.menuItem.price * item.quantity, 0);
  };

  return (
    <CartContext.Provider
      value={{
        cart,
        addToCart,
        removeFromCart,
        updateQuantity,
        clearCart,
        getTotal,
        isCartOpen,
        setIsCartOpen,
        createOrder,
      }}
    >
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const context = useContext(CartContext);
  if (!context) {
    throw new Error('useCart must be used within CartProvider');
  }
  return context;
}
