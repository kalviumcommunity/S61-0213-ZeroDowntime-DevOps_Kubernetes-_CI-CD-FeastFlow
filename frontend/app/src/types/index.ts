export interface Restaurant {
  id: string;
  name: string;
  cuisine: string;
  rating: number;
  deliveryTime: string;
  deliveryFee: string | number;
  image: string;
  tags: string[];
}

export interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: string;
  isPopular?: boolean;
}

export interface CartItem {
  menuItem: MenuItem;
  restaurant: Restaurant;
  quantity: number;
}
