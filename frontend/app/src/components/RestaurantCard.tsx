'use client';

import Image from 'next/image';
import Link from 'next/link';
import { Restaurant } from '@/types';

interface RestaurantCardProps {
  restaurant: Restaurant;
}

export default function RestaurantCard({ restaurant }: RestaurantCardProps) {
  return (
    <Link href={`/restaurant/${restaurant.id}`}>
      <div className="group cursor-pointer">
        {/* Image with Tags Overlay */}
        <div className="relative h-56 overflow-hidden rounded-2xl mb-3">
          <Image
            src={restaurant.image}
            alt={restaurant.name}
            fill
            className="object-cover group-hover:scale-105 transition-transform duration-300"
          />
          {/* Free Delivery Badge */}
          {restaurant.deliveryFee === 'Free' && (
            <div className="absolute top-3 left-3 bg-green-500 text-white px-3 py-1.5 rounded-lg text-xs font-semibold">
              Free Delivery
            </div>
          )}
          
          {/* Tags at bottom of image */}
          <div className="absolute bottom-3 left-3 flex gap-2">
            {restaurant.tags.map((tag) => (
              <span
                key={tag}
                className="px-3 py-1.5 bg-white/95 backdrop-blur-sm text-gray-800 rounded-lg text-xs font-medium shadow-sm"
              >
                {tag}
              </span>
            ))}
          </div>
        </div>

        {/* Content */}
        <div>
          {/* Name and Rating */}
          <div className="flex justify-between items-start mb-1">
            <h3 className="font-bold text-base text-gray-900">{restaurant.name}</h3>
            <div className="flex items-center gap-1">
              <svg className="w-4 h-4 text-orange-500" fill="currentColor" viewBox="0 0 20 20">
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.54 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              <span className="text-sm font-semibold text-gray-900">{restaurant.rating}</span>
            </div>
          </div>

          {/* Cuisine */}
          <p className="text-gray-500 text-sm mb-2">{restaurant.cuisine}</p>

          {/* Delivery Info */}
          <div className="flex items-center gap-1 text-sm text-gray-600">
            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            <span>{restaurant.deliveryTime}</span>
            <span className="mx-1">•</span>
            <span>
              {restaurant.deliveryFee === 'Free' ? 'Free delivery' : `$${restaurant.deliveryFee} delivery`}
            </span>
          </div>
        </div>
      </div>
    </Link>
  );
}
