'use client';

export default function AdminDashboard() {
  const metrics = [
    { label: 'Active Orders', value: '4,287', change: '+12.5%', trend: 'up' },
    { label: 'Revenue Today', value: '$127,450', change: '+8.3%', trend: 'up' },
    { label: 'Active Restaurants', value: '2,841', change: '-0.4%', trend: 'down' },
    { label: 'Avg Delivery Time', value: '28 min', change: '-2.1%', trend: 'down' },
    { label: 'Customer Rating', value: '4.6', change: '+0.1%', trend: 'up' },
    { label: 'API Latency', value: '42ms', change: '+5.2%', trend: 'up' },
  ];

  const revenueByCity = [
    { city: 'NYC', revenue: 45000 },
    { city: 'LA', revenue: 32000 },
    { city: 'Chi', revenue: 28000 },
    { city: 'SF', revenue: 24000 },
    { city: 'Mia', revenue: 18000 },
    { city: 'SEA', revenue: 15000 },
  ];

  const maxRevenue = Math.max(...revenueByCity.map(c => c.revenue));

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Dashboard Overview</h1>
        <p className="text-gray-600">Real-time platform metrics across 30+ cities</p>
      </div>

      {/* Metrics Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 mb-8">
        {metrics.map((metric, index) => (
          <div key={index} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <p className="text-sm text-gray-600 mb-2">{metric.label}</p>
            <div className="flex items-end justify-between">
              <h3 className="text-3xl font-bold text-gray-900">{metric.value}</h3>
              <div className={`flex items-center gap-1 text-sm font-medium ${
                metric.trend === 'up' 
                  ? metric.label === 'API Latency' ? 'text-red-500' : 'text-green-500'
                  : metric.label === 'Avg Delivery Time' ? 'text-green-500' : 'text-red-500'
              }`}>
                {metric.trend === 'up' ? (
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M5.293 9.707a1 1 0 010-1.414l4-4a1 1 0 011.414 0l4 4a1 1 0 01-1.414 1.414L11 7.414V15a1 1 0 11-2 0V7.414L6.707 9.707a1 1 0 01-1.414 0z" clipRule="evenodd" />
                  </svg>
                ) : (
                  <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M14.707 10.293a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 111.414-1.414L9 12.586V5a1 1 0 012 0v7.586l2.293-2.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                )}
                <span>{metric.change}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Orders Today Chart */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold text-gray-900 mb-6">Orders Today</h3>
          <div className="relative h-64">
            {/* Simple line chart visualization */}
            <svg className="w-full h-full" viewBox="0 0 600 200">
              <defs>
                <linearGradient id="orderGradient" x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stopColor="#FF6B35" stopOpacity="0.3" />
                  <stop offset="100%" stopColor="#FF6B35" stopOpacity="0.05" />
                </linearGradient>
              </defs>
              {/* Grid lines */}
              <line x1="0" y1="50" x2="600" y2="50" stroke="#e5e7eb" strokeWidth="1" />
              <line x1="0" y1="100" x2="600" y2="100" stroke="#e5e7eb" strokeWidth="1" />
              <line x1="0" y1="150" x2="600" y2="150" stroke="#e5e7eb" strokeWidth="1" />
              
              {/* Line chart path */}
              <path
                d="M 50 120 L 120 100 L 190 110 L 260 60 L 330 100 L 400 40 L 470 70 L 540 130"
                fill="url(#orderGradient)"
                stroke="#FF6B35"
                strokeWidth="3"
                fillOpacity="0.3"
              />
              <path
                d="M 50 120 L 120 100 L 190 110 L 260 60 L 330 100 L 400 40 L 470 70 L 540 130"
                fill="none"
                stroke="#FF6B35"
                strokeWidth="3"
              />
              
              {/* X-axis labels */}
              <text x="50" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">6AM</text>
              <text x="120" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">8AM</text>
              <text x="190" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">10AM</text>
              <text x="260" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">12PM</text>
              <text x="330" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">2PM</text>
              <text x="400" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">4PM</text>
              <text x="470" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">6PM</text>
              <text x="540" y="195" fontSize="12" fill="#9ca3af" textAnchor="middle">8PM</text>
            </svg>
          </div>
        </div>

        {/* Revenue by City Chart */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h3 className="text-lg font-bold text-gray-900 mb-6">Revenue by City</h3>
          <div className="h-64 flex items-end justify-between gap-4 px-4">
            {revenueByCity.map((item, index) => {
              const height = (item.revenue / maxRevenue) * 100;
              return (
                <div key={index} className="flex flex-col items-center flex-1">
                  <div className="w-full flex items-end justify-center mb-2" style={{ height: '200px' }}>
                    <div
                      className="w-full bg-orange-500 rounded-t-lg transition-all hover:bg-orange-600"
                      style={{ height: `${height}%` }}
                    />
                  </div>
                  <span className="text-sm text-gray-600 font-medium">{item.city}</span>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}
