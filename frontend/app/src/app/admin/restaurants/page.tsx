'use client';

import { useState } from 'react';

interface Restaurant {
  id: number;
  name: string;
  cuisine: string;
  city: string;
  rating: number;
  orders: number;
  revenue: number;
  enabled: boolean;
}

const restaurantsData: Restaurant[] = [
  { id: 1, name: 'Sakura Zen', cuisine: 'Japanese', city: 'New York', rating: 4.8, orders: 12450, revenue: 2850000, enabled: true },
  { id: 2, name: 'Napoli Fire', cuisine: 'Italian', city: 'New York', rating: 4.6, orders: 9800, revenue: 1980000, enabled: true },
  { id: 3, name: 'Smash Stack', cuisine: 'American', city: 'New York', rating: 4.5, orders: 15200, revenue: 3120000, enabled: true },
  { id: 4, name: 'Spice Route', cuisine: 'Indian', city: 'Chicago', rating: 4.7, orders: 8900, revenue: 1760000, enabled: true },
  { id: 5, name: 'El Fuego', cuisine: 'Mexican', city: 'Los Angeles', rating: 4.4, orders: 6700, revenue: 1340000, enabled: false },
  { id: 6, name: 'Thai Orchid', cuisine: 'Thai', city: 'San Francisco', rating: 4.3, orders: 5400, revenue: 1080000, enabled: true },
  { id: 7, name: 'Dragon Wok', cuisine: 'Chinese', city: 'Seattle', rating: 4.2, orders: 7800, revenue: 1560000, enabled: true },
  { id: 8, name: 'Med Breeze', cuisine: 'Mediterranean', city: 'Miami', rating: 4.6, orders: 4300, revenue: 980000, enabled: true },
];

export default function RestaurantsPage() {
  const [selectedCity, setSelectedCity] = useState('All');
  const [searchQuery, setSearchQuery] = useState('');

  const cities = ['All', 'New York', 'Chicago', 'Los Angeles', 'San Francisco', 'Seattle', 'Miami'];

  const filteredRestaurants = restaurantsData.filter(r => {
    const matchesCity = selectedCity === 'All' || r.city === selectedCity;
    const matchesSearch = r.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
                         r.cuisine.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCity && matchesSearch;
  });

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Restaurant Management</h1>
        <p className="text-gray-600">Enable/disable restaurants and manage per-city availability</p>
      </div>

      {/* Filters */}
      <div className="mb-6 flex items-center gap-4">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <svg className="absolute left-3 top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder="Search restaurants..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-orange-500"
          />
        </div>

        {/* City Filter */}
        <div className="flex gap-2">
          {cities.map((city) => (
            <button
              key={city}
              onClick={() => setSelectedCity(city)}
              className={`px-4 py-2.5 rounded-lg font-medium transition-colors ${
                selectedCity === city
                  ? 'bg-orange-500 text-white'
                  : 'bg-white text-gray-700 border border-gray-200 hover:bg-gray-50'
              }`}
            >
              {city}
            </button>
          ))}
        </div>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Restaurant</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">City</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Rating</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Orders</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Revenue</th>
              <th className="px-6 py-4 text-left text-sm font-semibold text-gray-900">Status</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-200">
            {filteredRestaurants.map((restaurant) => (
              <tr key={restaurant.id} className="hover:bg-gray-50 transition-colors">
                <td className="px-6 py-4">
                  <div>
                    <div className="font-semibold text-gray-900">{restaurant.name}</div>
                    <div className="text-sm text-gray-500">{restaurant.cuisine}</div>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-2 text-gray-700">
                    <svg className="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                    </svg>
                    <span>{restaurant.city}</span>
                  </div>
                </td>
                <td className="px-6 py-4">
                  <div className="flex items-center gap-1">
                    <svg className="w-4 h-4 text-orange-500" fill="currentColor" viewBox="0 0 20 20">
                      <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
                    </svg>
                    <span className="font-medium text-gray-900">{restaurant.rating}</span>
                  </div>
                </td>
                <td className="px-6 py-4 text-gray-900">{restaurant.orders.toLocaleString()}</td>
                <td className="px-6 py-4 font-medium text-gray-900">
                  ${(restaurant.revenue / 1000).toFixed(0)}K
                </td>
                <td className="px-6 py-4">
                  <button
                    className={`px-4 py-2 rounded-lg text-sm font-semibold flex items-center gap-2 ${
                      restaurant.enabled
                        ? 'bg-green-50 text-green-700'
                        : 'bg-red-50 text-red-700'
                    }`}
                  >
                    <div className={`w-2 h-2 rounded-full ${restaurant.enabled ? 'bg-green-500' : 'bg-red-500'}`} />
                    {restaurant.enabled ? 'Enabled' : 'Disabled'}
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
