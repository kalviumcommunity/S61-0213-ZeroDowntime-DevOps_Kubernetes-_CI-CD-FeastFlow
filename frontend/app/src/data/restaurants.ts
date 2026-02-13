import { Restaurant, MenuItem } from '@/types';

export const restaurants: Restaurant[] = [
  {
    id: '1',
    name: 'Sakura Zen',
    cuisine: 'Japanese',
    rating: 4.8,
    deliveryTime: '25-35 min',
    deliveryFee: 2.99,
    image: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    tags: ['Sushi', 'Ramen', 'Premium']
  },
  {
    id: '2',
    name: 'Napoli Fire',
    cuisine: 'Italian',
    rating: 4.6,
    deliveryTime: '30-40 min',
    deliveryFee: 1.99,
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop',
    tags: ['Pizza', 'Pasta', 'Wood-fired']
  },
  {
    id: '3',
    name: 'Smash Stack',
    cuisine: 'American',
    rating: 4.5,
    deliveryTime: '20-30 min',
    deliveryFee: 'Free',
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop',
    tags: ['Burgers', 'Fries', 'Free Delivery']
  },
  {
    id: '4',
    name: 'Spice Route',
    cuisine: 'Indian',
    rating: 4.7,
    deliveryTime: '35-45 min',
    deliveryFee: 3.49,
    image: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&h=600&fit=crop',
    tags: ['Curry', 'Tandoori', 'Spicy']
  },
  {
    id: '5',
    name: 'El Fuego',
    cuisine: 'Mexican',
    rating: 4.4,
    deliveryTime: '25-35 min',
    deliveryFee: 1.49,
    image: 'https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800&h=600&fit=crop',
    tags: ['Tacos', 'Burritos', 'Fresh']
  }
];

export const menuItems: Record<string, MenuItem[]> = {
  '1': [ // Sakura Zen
    {
      id: '1-1',
      name: 'Dragon Roll',
      description: 'Shrimp tempura, avocado, eel sauce, tobiko',
      price: 16.99,
      category: 'Rolls',
      isPopular: true
    },
    {
      id: '1-2',
      name: 'Spicy Tuna Roll',
      description: 'Fresh tuna, spicy mayo, cucumber',
      price: 14.99,
      category: 'Rolls'
    },
    {
      id: '1-3',
      name: 'Tonkotsu Ramen',
      description: 'Rich pork broth, chashu, soft egg, nori',
      price: 18.99,
      category: 'Ramen',
      isPopular: true
    },
    {
      id: '1-4',
      name: 'Edamame',
      description: 'Steamed soybeans with sea salt',
      price: 5.99,
      category: 'Starters'
    },
    {
      id: '1-5',
      name: 'Miso Soup',
      description: 'Traditional dashi broth with tofu and wakame',
      price: 4.99,
      category: 'Starters'
    },
    {
      id: '1-6',
      name: 'Salmon Sashimi',
      description: '8 pieces of fresh salmon',
      price: 19.99,
      category: 'Sashimi'
    }
  ]
};
