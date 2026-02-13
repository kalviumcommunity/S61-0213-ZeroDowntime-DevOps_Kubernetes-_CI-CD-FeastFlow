'use client';

interface PricingRule {
  id: number;
  name: string;
  type: 'SURGE' | 'DISCOUNT' | 'FLAT';
  multiplier: number;
  timeRange: string;
  cities: string;
  active: boolean;
  icon: string;
  iconBg: string;
}

const pricingRules: PricingRule[] = [
  {
    id: 1,
    name: 'Dinner Rush Surge',
    type: 'SURGE',
    multiplier: 1.25,
    timeRange: '6:00 PM - 9:00 PM',
    cities: 'New York, Los Angeles, Chicago',
    active: true,
    icon: '⚡',
    iconBg: 'bg-red-50',
  },
  {
    id: 2,
    name: 'Late Night Premium',
    type: 'SURGE',
    multiplier: 1.15,
    timeRange: '10:00 PM - 2:00 AM',
    cities: 'New York, San Francisco',
    active: true,
    icon: '⚡',
    iconBg: 'bg-red-50',
  },
  {
    id: 3,
    name: 'Weekday Lunch Discount',
    type: 'DISCOUNT',
    multiplier: 0.9,
    timeRange: '11:00 AM - 2:00 PM',
    cities: 'All',
    active: false,
    icon: '%',
    iconBg: 'bg-green-50',
  },
  {
    id: 4,
    name: 'Weekend Brunch',
    type: 'FLAT',
    multiplier: 1.0,
    timeRange: '9:00 AM - 1:00 PM',
    cities: 'New York, Miami',
    active: true,
    icon: '$',
    iconBg: 'bg-orange-50',
  },
];

export default function PricingPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Pricing Algorithms</h1>
        <p className="text-gray-600">Configure surge pricing, discounts, and flat-rate rules</p>
      </div>

      {/* Pricing Rules Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {pricingRules.map((rule) => (
          <div
            key={rule.id}
            className="bg-white rounded-xl p-6 shadow-sm border border-gray-100"
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center gap-4">
                <div className={`w-14 h-14 ${rule.iconBg} rounded-xl flex items-center justify-center text-2xl`}>
                  {rule.icon}
                </div>
                <div>
                  <h3 className="text-lg font-bold text-gray-900 mb-1">{rule.name}</h3>
                  <span className={`text-xs font-bold uppercase ${
                    rule.type === 'SURGE' ? 'text-red-600' :
                    rule.type === 'DISCOUNT' ? 'text-green-600' :
                    'text-orange-600'
                  }`}>
                    {rule.type}
                  </span>
                </div>
              </div>
              <button
                className={`px-4 py-2 rounded-lg text-sm font-semibold ${
                  rule.active
                    ? 'bg-green-50 text-green-700'
                    : 'bg-gray-100 text-gray-600'
                }`}
              >
                {rule.active ? 'Active' : 'Inactive'}
              </button>
            </div>

            {/* Details */}
            <div className="space-y-3">
              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="text-sm">
                  <span className="text-gray-500">Multiplier:</span>{' '}
                  <span className="font-semibold">{rule.multiplier}x</span>
                </span>
              </div>

              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
                <span className="text-sm text-gray-600">{rule.timeRange}</span>
              </div>

              <div className="flex items-center gap-3 text-gray-700">
                <svg className="w-5 h-5 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z" />
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 11a3 3 0 11-6 0 3 3 0 016 0z" />
                </svg>
                <span className="text-sm text-gray-600">{rule.cities}</span>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
