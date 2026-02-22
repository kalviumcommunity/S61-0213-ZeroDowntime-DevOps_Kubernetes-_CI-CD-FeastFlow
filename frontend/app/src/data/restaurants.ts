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
  ],
  '2': [ // Napoli Fire
    {
      id: '2-1',
      name: 'Margherita Pizza',
      description: 'San Marzano tomatoes, fresh mozzarella, basil',
      price: 13.99,
      category: 'Pizza',
      isPopular: true
    },
    {
      id: '2-2',
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
  '3': [ // Smash Stack
    {
      id: '3-1',
      name: 'Classic Smash Burger',
      description: 'Double smashed patties, american cheese, special sauce',
      price: 11.99,
      category: 'Burgers',
      isPopular: true
    },
    {
      id: '3-2',
      name: 'Bacon Cheeseburger',
      description: 'Smashed beef, crispy bacon, cheddar, BBQ sauce',
      price: 13.99,
      category: 'Burgers',
      isPopular: true
    },
    {
      id: '3-3',
      name: 'Veggie Burger',
      description: 'Plant-based patty, lettuce, tomato, avocado',
      price: 10.99,
      category: 'Burgers'
    },
    {
      id: '3-4',
      name: 'Loaded Fries',
      description: 'Crispy fries, cheese sauce, bacon, jalapeños',
      price: 8.99,
      category: 'Sides',
      isPopular: true
    },
    {
      id: '3-5',
      name: 'Onion Rings',
      description: 'Beer-battered crispy onion rings',
      price: 6.99,
      category: 'Sides'
    },
    {
      id: '3-6',
      name: 'Chocolate Shake',
      description: 'Thick handmade chocolate milkshake',
      price: 5.99,
      category: 'Drinks'
    }
  ],
  '4': [ // Spice Route
    {
      id: '4-1',
      name: 'Butter Chicken',
      description: 'Tender chicken in creamy tomato-based curry',
      price: 16.99,
      category: 'Curry',
      isPopular: true
    },
    {
      id: '4-2',
      name: 'Chicken Tikka Masala',
      description: 'Grilled chicken in spiced tomato cream sauce',
      price: 15.99,
      category: 'Curry',
      isPopular: true
    },
    {
      id: '4-3',
      name: 'Lamb Vindaloo',
      description: 'Spicy lamb curry with potatoes and chilies',
      price: 18.99,
      category: 'Curry'
    },
    {
      id: '4-4',
      name: 'Tandoori Chicken',
      description: 'Clay oven roasted chicken with yogurt marinade',
      price: 17.99,
      category: 'Tandoori',
      isPopular: true
    },
    {
      id: '4-5',
      name: 'Garlic Naan',
      description: 'Fresh flatbread with garlic and butter',
      price: 3.99,
      category: 'Breads'
    },
    {
      id: '4-6',
      name: 'Samosas (3pc)',
      description: 'Crispy pastries filled with spiced potatoes and peas',
      price: 6.99,
      category: 'Starters'
    }
  ],
  '5': [ // El Fuego
    {
      id: '5-1',
      name: 'Street Tacos (3pc)',
      description: 'Choice of carnitas, carne asada, or chicken with cilantro and onions',
      price: 12.99,
      category: 'Tacos',
      isPopular: true
    },
    {
      id: '5-2',
      name: 'Fish Tacos (3pc)',
      description: 'Battered fish, cabbage slaw, chipotle mayo, lime',
      price: 14.99,
      category: 'Tacos',
      isPopular: true
    },
    {
      id: '5-3',
      name: 'California Burrito',
      description: 'Carne asada, fries, cheese, guacamole, sour cream',
      price: 13.99,
      category: 'Burritos',
      isPopular: true
    },
    {
      id: '5-4',
      name: 'Chicken Burrito Bowl',
      description: 'Rice, beans, grilled chicken, salsa, cheese, lettuce',
      price: 11.99,
      category: 'Burritos'
    },
    {
      id: '5-5',
      name: 'Queso Fundido',
      description: 'Melted cheese with chorizo and tortillas',
      price: 8.99,
      category: 'Starters'
    },
    {
      id: '5-6',
      name: 'Nachos Supreme',
      description: 'Loaded nachos with beans, cheese, jalapeños, pico de gallo',
      price: 10.99,
      category: 'Starters'
    },
    {
      id: '5-7',
      name: 'Churros',
      description: 'Cinnamon sugar churros with chocolate sauce',
      price: 6.99,
      category: 'Desserts'
    }
  ]
};
