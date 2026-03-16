import { Restaurant, MenuItem } from '@/types';

export const restaurants: Restaurant[] = [
  {
    id: '7e1e2b2a-1c2d-4e3f-8a9b-1b2c3d4e5f61',
    name: 'Sakura Zen',
    cuisine: 'Japanese',
    rating: 4.8,
    deliveryTime: '25-35 min',
    deliveryFee: 2.99,
    image: 'https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800&h=600&fit=crop',
    tags: ['Sushi', 'Ramen', 'Premium']
  },
  {
    id: '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c72',
    name: 'Napoli Fire',
    cuisine: 'Italian',
    rating: 4.6,
    deliveryTime: '30-40 min',
    deliveryFee: 1.99,
    image: 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&h=600&fit=crop',
    tags: ['Pizza', 'Pasta', 'Wood-fired']
  },
  {
    id: '3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e83',
    name: 'Smash Stack',
    cuisine: 'American',
    rating: 4.5,
    deliveryTime: '20-30 min',
    deliveryFee: 'Free',
    image: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&h=600&fit=crop',
    tags: ['Burgers', 'Fries', 'Free Delivery']
  },
  {
    id: '4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f94',
    name: 'Spice Route',
    cuisine: 'Indian',
    rating: 4.7,
    deliveryTime: '35-45 min',
    deliveryFee: 3.49,
    image: 'https://images.unsplash.com/photo-1585937421612-70a008356fbe?w=800&h=600&fit=crop',
    tags: ['Curry', 'Tandoori', 'Spicy']
  },
  {
    id: '5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a05',
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
  '7e1e2b2a-1c2d-4e3f-8a9b-1b2c3d4e5f61': [ // Sakura Zen
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c61',
      name: 'Dragon Roll',
      description: 'Shrimp tempura, avocado, eel sauce, tobiko',
      price: 16.99,
      category: 'Rolls',
      isPopular: true
    },
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c62',
      name: 'Spicy Tuna Roll',
      description: 'Fresh tuna, spicy mayo, cucumber',
      price: 14.99,
      category: 'Rolls'
    },
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c63',
      name: 'Tonkotsu Ramen',
      description: 'Rich pork broth, chashu, soft egg, nori',
      price: 18.99,
      category: 'Ramen',
      isPopular: true
    },
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c64',
      name: 'Edamame',
      description: 'Steamed soybeans with sea salt',
      price: 5.99,
      category: 'Starters'
    },
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c65',
      name: 'Miso Soup',
      description: 'Traditional dashi broth with tofu and wakame',
      price: 4.99,
      category: 'Starters'
    },
    {
      id: 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c66',
      name: 'Salmon Sashimi',
      description: '8 pieces of fresh salmon',
      price: 19.99,
      category: 'Sashimi'
    }
  ],
  '2a3b4c5d-6e7f-8a9b-0c1d-2e3f4a5b6c72': [ // Napoli Fire
    {
      id: 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d71',
      name: 'Margherita Pizza',
      description: 'San Marzano tomatoes, fresh mozzarella, basil',
      price: 13.99,
      category: 'Pizza',
      isPopular: true
    },
    {
      id: 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d72',
      name: 'Pepperoni Deluxe',
      description: 'Double pepperoni, mozzarella, oregano',
      price: 15.99,
      category: 'Pizza',
      isPopular: true
    },
    {
      id: '2-3',
      name: 'Spaghetti Carbonara',
      description: 'Eggs, pecorino, guanciale, black pepper',
      price: 14.99,
      category: 'Pasta'
    },
    {
      id: '2-4',
      name: 'Fettuccine Alfredo',
      description: 'Cream, parmesan, butter, garlic',
      price: 13.99,
      category: 'Pasta'
    },
    {
      id: '2-5',
      name: 'Bruschetta',
      description: 'Tomatoes, garlic, basil, olive oil on toasted bread',
      price: 6.99,
      category: 'Starters'
    },
    {
      id: '2-6',
      name: 'Tiramisu',
      description: 'Classic Italian dessert with espresso and mascarpone',
      price: 7.99,
      category: 'Desserts'
    }
  ],
  '3c4d5e6f-7a8b-9c0d-1e2f-3a4b5c6d7e83': [ // Smash Stack
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e81',
      name: 'Classic Smash Burger',
      description: 'Double smashed patties, american cheese, special sauce',
      price: 11.99,
      category: 'Burgers',
      isPopular: true
    },
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e82',
      name: 'Bacon Cheeseburger',
      description: 'Smashed beef, crispy bacon, cheddar, BBQ sauce',
      price: 13.99,
      category: 'Burgers',
      isPopular: true
    },
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e83',
      name: 'Veggie Burger',
      description: 'Plant-based patty, lettuce, tomato, avocado',
      price: 10.99,
      category: 'Burgers'
    },
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e84',
      name: 'Loaded Fries',
      description: 'Crispy fries, cheese sauce, bacon, jalapeños',
      price: 8.99,
      category: 'Sides',
      isPopular: true
    },
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e85',
      name: 'Onion Rings',
      description: 'Beer-battered crispy onion rings',
      price: 6.99,
      category: 'Sides'
    },
    {
      id: 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e86',
      name: 'Chocolate Shake',
      description: 'Thick handmade chocolate milkshake',
      price: 5.99,
      category: 'Drinks'
    }
  ],
  '4d5e6f7a-8b9c-0d1e-2f3a-4b5c6d7e8f94': [ // Spice Route
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f91',
      name: 'Butter Chicken',
      description: 'Tender chicken in creamy tomato-based curry',
      price: 16.99,
      category: 'Curry',
      isPopular: true
    },
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f92',
      name: 'Chicken Tikka Masala',
      description: 'Grilled chicken in spiced tomato cream sauce',
      price: 15.99,
      category: 'Curry',
      isPopular: true
    },
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f93',
      name: 'Lamb Vindaloo',
      description: 'Spicy lamb curry with potatoes and chilies',
      price: 18.99,
      category: 'Curry'
    },
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f94',
      name: 'Tandoori Chicken',
      description: 'Clay oven roasted chicken with yogurt marinade',
      price: 17.99,
      category: 'Tandoori',
      isPopular: true
    },
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f95',
      name: 'Garlic Naan',
      description: 'Fresh flatbread with garlic and butter',
      price: 3.99,
      category: 'Breads'
    },
    {
      id: 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f96',
      name: 'Samosas (3pc)',
      description: 'Crispy pastries filled with spiced potatoes and peas',
      price: 6.99,
      category: 'Starters'
    }
  ],
  '5e6f7a8b-9c0d-1e2f-3a4b-5c6d7e8f9a05': [ // El Fuego
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a01',
      name: 'Street Tacos (3pc)',
      description: 'Choice of carnitas, carne asada, or chicken with cilantro and onions',
      price: 12.99,
      category: 'Tacos',
      isPopular: true
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a02',
      name: 'Fish Tacos (3pc)',
      description: 'Battered fish, cabbage slaw, chipotle mayo, lime',
      price: 14.99,
      category: 'Tacos',
      isPopular: true
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a03',
      name: 'California Burrito',
      description: 'Carne asada, fries, cheese, guacamole, sour cream',
      price: 13.99,
      category: 'Burritos',
      isPopular: true
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a04',
      name: 'Chicken Burrito Bowl',
      description: 'Rice, beans, grilled chicken, salsa, cheese, lettuce',
      price: 11.99,
      category: 'Burritos'
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a05',
      name: 'Queso Fundido',
      description: 'Melted cheese with chorizo and tortillas',
      price: 8.99,
      category: 'Starters'
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a06',
      name: 'Nachos Supreme',
      description: 'Loaded nachos with beans, cheese, jalapeños, pico de gallo',
      price: 10.99,
      category: 'Starters'
    },
    {
      id: 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a07',
      name: 'Churros',
      description: 'Cinnamon sugar churros with chocolate sauce',
      price: 6.99,
      category: 'Desserts'
    }
  ]
};
