'use client';

interface Service {
  id: number;
  name: string;
  status: 'HEALTHY' | 'DEGRADED' | 'DOWN';
  latency: string;
  uptime: string;
  icon: string;
  iconBg: string;
}

const services: Service[] = [
  {
    id: 1,
    name: 'API Gateway',
    status: 'HEALTHY',
    latency: '10ms',
    uptime: '99.99%',
    icon: '🖥️',
    iconBg: 'bg-green-50',
  },
  {
    id: 2,
    name: 'Order Service',
    status: 'HEALTHY',
    latency: '26ms',
    uptime: '99.97%',
    icon: '📊',
    iconBg: 'bg-green-50',
  },
  {
    id: 3,
    name: 'Payment Service',
    status: 'HEALTHY',
    latency: '49ms',
    uptime: '99.95%',
    icon: '📡',
    iconBg: 'bg-green-50',
  },
  {
    id: 4,
    name: 'Database Cluster',
    status: 'HEALTHY',
    latency: '3ms',
    uptime: '99.99%',
    icon: '💾',
    iconBg: 'bg-green-50',
  },
  {
    id: 5,
    name: 'Redis Cache',
    status: 'HEALTHY',
    latency: '6ms',
    uptime: '99.99%',
    icon: '🔄',
    iconBg: 'bg-green-50',
  },
  {
    id: 6,
    name: 'CDN / Assets',
    status: 'HEALTHY',
    latency: '1ms',
    uptime: '100%',
    icon: '☁️',
    iconBg: 'bg-green-50',
  },
];

export default function SystemHealthPage() {
  const healthyServices = services.filter(s => s.status === 'HEALTHY').length;
  const totalServices = services.length;

  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">System Health</h1>
        <p className="text-gray-600">Kubernetes cluster and microservice status — live updates</p>
      </div>

      {/* Overall Status Banner */}
      <div className="bg-green-50 border border-green-200 rounded-xl p-6 mb-8">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 bg-green-100 rounded-full flex items-center justify-center">
            <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <div>
            <h2 className="text-xl font-bold text-gray-900 mb-1">All Systems Operational</h2>
            <p className="text-gray-700">
              {healthyServices}/{totalServices} services healthy • Last checked just now
            </p>
          </div>
        </div>
      </div>

      {/* Services Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {services.map((service) => (
          <div
            key={service.id}
            className="bg-white rounded-xl p-6 shadow-sm border border-gray-100"
          >
            {/* Header */}
            <div className="flex items-start justify-between mb-6">
              <div className="flex items-center gap-3">
                <div className={`w-12 h-12 ${service.iconBg} rounded-xl flex items-center justify-center text-xl`}>
                  {service.icon}
                </div>
                <div>
                  <h3 className="font-bold text-gray-900 mb-1">{service.name}</h3>
                  <span className="text-xs font-bold uppercase text-green-600">
                    {service.status}
                  </span>
                </div>
              </div>
            </div>

            {/* Metrics */}
            <div className="grid grid-cols-2 gap-4">
              <div>
                <p className="text-sm text-gray-500 mb-1">Latency</p>
                <p className="text-xl font-bold text-gray-900">{service.latency}</p>
              </div>
              <div>
                <p className="text-sm text-gray-500 mb-1">Uptime</p>
                <p className="text-xl font-bold text-gray-900">{service.uptime}</p>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
