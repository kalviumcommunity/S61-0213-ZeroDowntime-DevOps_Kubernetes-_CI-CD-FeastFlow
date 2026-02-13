'use client';

import { useState } from 'react';
import RestaurantCard from '@/components/RestaurantCard';
import { restaurants } from '@/data/restaurants';

const categories = ['All', 'Japanese', 'Italian', 'American', 'Indian', 'Mexican', 'Thai', 'Chinese', 'Mediterranean'];

export default function Home() {
  const [selectedCategory, setSelectedCategory] = useState('All');

  const filteredRestaurants = selectedCategory === 'All'
    ? restaurants
    : restaurants.filter(r => r.cuisine === selectedCategory);

  return (
    <div className="min-h-screen bg-gray-50">
      {/* Hero Section */}
      <div 
        className="relative h-96 bg-cover bg-center"
        style={{
          backgroundImage: 'url(https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1600&h=600&fit=crop)',
          backgroundPosition: 'center'
        }}
      >
        <div className="absolute inset-0 bg-gradient-to-r from-black/70 to-black/50" />
        <div className="relative max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-full flex flex-col justify-center">
          <div className="flex items-center gap-2 text-orange-400 mb-6">
            <span className="text-lg">🍴</span>
            <span className="text-sm font-medium">Delivering across 40+ cities</span>
          </div>
          <h1 className="text-6xl font-bold text-white leading-tight mb-2">Crave it.</h1>
          <h1 className="text-6xl font-bold text-white leading-tight mb-6">We bring it.</h1>
          <p className="text-gray-200 text-base mb-8 max-w-xl">
            Real-time menus. Dynamic pricing. Thousands of restaurants at your fingertips.
          </p>
          <button className="flex items-center gap-2 px-6 py-3.5 bg-orange-500 text-white rounded-lg font-semibold hover:bg-orange-600 transition-colors w-fit shadow-lg">
            Explore Restaurants
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8l4 4m0 0l-4 4m4-4H3" />
            </svg>
          </button>
        </div>
      </div>

      {/* Category Filter */}
      <div className="bg-white border-b border-gray-200 sticky top-16 z-30">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex gap-3 py-4 overflow-x-auto scrollbar-hide">
            {categories.map((category) => (
              <button
                key={category}
                onClick={() => setSelectedCategory(category)}
                className={`px-6 py-2 rounded-full font-medium whitespace-nowrap transition-colors ${
                  selectedCategory === category
                    ? 'bg-orange-500 text-white'
                    : 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                }`}
              >
                {category}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Restaurant Grid */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        <div className="mb-6">
          <h2 className="text-2xl font-bold text-gray-900 mb-2">Restaurants in New York</h2>
          <p className="text-gray-600">
            {filteredRestaurants.length} restaurants available • Prices update in real-time
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {filteredRestaurants.map((restaurant) => (
            <RestaurantCard key={restaurant.id} restaurant={restaurant} />
          ))}
        </div>
      </div>
    </div>
  );
}
