'use client';

interface Promotion {
  id: number;
  name: string;
  code: string;
  discount: string;
  dateRange: string;
  cities: string;
  uses: number;
  active: boolean;
}

const promotions: Promotion[] = [
  {
    id: 1,
    name: 'New User Welcome',
    code: 'WELCOME20',
    discount: '20% OFF',
    dateRange: '2026-01-01 → 2026-03-31',
    cities: 'All',
    uses: 34500,
    active: true,
  },
  {
    id: 2,
    name: 'NYC Pizza Week',
    code: 'NYCPIZZA',
    discount: '15% OFF',
    dateRange: '2026-02-10 → 2026-02-17',
    cities: 'New York',
    uses: 8200,
    active: true,
  },
  {
    id: 3,
    name: 'Free Delivery LA',
    code: 'FREEDELIVLA',
    discount: '',
    dateRange: '2026-02-01 → 2026-02-28',
    cities: 'Los Angeles',
    uses: 12100,
    active: true,
  },
  {
    id: 4,
    name: 'Holiday Special',
    code: 'HOLIDAY25',
    discount: '25% OFF',
    dateRange: '2025-12-20 → 2026-01-05',
    cities: 'All',
    uses: 67800,
    active: false,
  },
];

export default function PromotionsPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Promotions</h1>
        <p className="text-gray-600">Manage city-specific promotions and discount codes</p>
      </div>

      {/* Promotions Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {promotions.map((promo) => (
          <div
            key={promo.id}
            className="bg-white rounded-xl p-6 shadow-sm border border-gray-100"
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center gap-4">
                <div className="w-14 h-14 bg-purple-50 rounded-xl flex items-center justify-center text-2xl">
                  📢
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900 mb-1">{promo.name}</h3>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold uppercase text-orange-600">
                      {promo.code}
                    </span>
                    <button className="text-gray-400 hover:text-gray-600">
                      <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
              <button
                className={`px-4 py-2 rounded-lg text-sm font-semibold ${
                  promo.active
                    ? 'bg-green-50 text-green-700'
                    : 'bg-gray-100 text-gray-600'
                }`}
              >
                {promo.active ? 'Active' : 'Inactive'}
              </button>
            </div>

            {/* Discount Badge */}
            {promo.discount && (
              <div className="mb-4">
                <h2 className="text-3xl font-bold text-orange-500">{promo.discount}</h2>
              </div>
            )}

            {/* Details */}
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                </svg>
                <span className="text-sm text-gray-600">{promo.dateRange}</span>
              </div>

              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                <span className="text-sm text-gray-600">{promo.cities}</span>
              </div>

              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
                <span className="text-sm text-gray-600">{promo.uses.toLocaleString()} uses</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
