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
}

const CartContext = createContext<CartContextType | undefined>(undefined);

export function CartProvider({ children }: { children: ReactNode }) {
  const [cart, setCart] = useState<CartItem[]>([]);
  const [isCartOpen, setIsCartOpen] = useState(false);
  const { user } = useAuth();

  const API_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:5000/api';

  const loadCart = useCallback(async () => {
    const token = localStorage.getItem('token');
    
    if (!token) {
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
        if (data.success && data.data.items) {
          interface BackendCartItem {
            menu_item_id: string;
            menu_item_name: string;
            menu_item_price: string;
            menu_item_description: string;
            menu_item_category: string;
            restaurant_id: string;
            restaurant_name: string;
            quantity: number;
          }
          // Convert backend format to frontend format
          const cartItems: CartItem[] = data.data.items.map((item: BackendCartItem) => ({
            menuItem: {
              id: item.menu_item_id,
              name: item.menu_item_name,
              price: parseFloat(item.menu_item_price),
              description: item.menu_item_description,
              category: item.menu_item_category,
            },
            restaurant: {
              id: item.restaurant_id,
              name: item.restaurant_name,
            },
            quantity: item.quantity,
          }));
          setCart(cartItems);
        }
      }
    } catch (error) {
      console.error('Error loading cart from backend:', error);
    }
  }, [API_URL]);

  // Load cart from backend when user logs in
  useEffect(() => {
    if (user) {
      loadCart();
    } else {
      // Clear cart when user logs out
      setCart([]);
    }
  }, [user, loadCart]);

  const addToCart = async (menuItem: MenuItem, restaurant: Restaurant) => {
    const token = localStorage.getItem('token');

    if (!token || !user) {
      alert('Please log in to add items to cart');
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
      } else {
        const data = await response.json();
        alert(data.message || 'Failed to add item to cart');
      }
    } catch (error) {
      console.error('Error adding to cart:', error);
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
      removeFromCart(itemId);
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
