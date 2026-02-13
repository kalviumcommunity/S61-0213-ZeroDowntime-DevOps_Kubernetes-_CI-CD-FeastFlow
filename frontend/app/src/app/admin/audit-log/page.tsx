'use client';

interface AuditLogEntry {
  id: number;
  action: string;
  target: string;
  description: string;
  user: string;
  timestamp: string;
  type: 'warning' | 'error' | 'info' | 'success';
}

const auditLogs: AuditLogEntry[] = [
  {
    id: 1,
    action: 'Updated pricing',
    target: 'Dinner Rush Surge',
    description: 'Changed multiplier from 1.2x to 1.25x',
    user: 'admin@feastflow.com',
    timestamp: '2026-02-13 14:32:11',
    type: 'warning',
  },
  {
    id: 2,
    action: 'Disabled restaurant',
    target: 'El Fuego',
    description: 'Temporarily disabled due to health inspection',
    user: 'ops@feastflow.com',
    timestamp: '2026-02-13 13:15:44',
    type: 'error',
  },
  {
    id: 3,
    action: 'Created promotion',
    target: 'NYC Pizza Week',
    description: '15% discount for New York users',
    user: 'admin@feastflow.com',
    timestamp: '2026-02-13 11:45:22',
    type: 'info',
  },
  {
    id: 4,
    action: 'Menu update',
    target: 'Sakura Zen',
    description: 'Added 3 new items to Rolls category',
    user: 'ops@feastflow.com',
    timestamp: '2026-02-12 22:10:33',
    type: 'info',
  },
  {
    id: 5,
    action: 'Launched city',
    target: 'Portland',
    description: 'New city launched with 12 restaurants',
    user: 'admin@feastflow.com',
    timestamp: '2026-02-12 18:05:17',
    type: 'success',
  },
  {
    id: 6,
    action: 'Updated RBAC',
    target: 'ops@feastflow.com',
    description: 'Granted restaurant management permissions',
    user: 'admin@feastflow.com',
    timestamp: '2026-02-12 15:30:09',
    type: 'warning',
  },
  {
    id: 7,
    action: 'Auto-surge activated',
    target: 'All NYC restaurants',
    description: 'Surge pricing triggered: demand 2.3x normal',
    user: 'system',
    timestamp: '2026-02-12 09:12:55',
    type: 'warning',
  },
  {
    id: 8,
    action: 'Bulk price update',
    target: 'Chicago restaurants',
    description: 'Adjusted base prices by +3% for inflation',
    user: 'admin@feastflow.com',
    timestamp: '2026-02-11 20:45:00',
    type: 'error',
  },
];

const iconMap = {
  warning: {
    color: 'bg-yellow-50 text-yellow-600',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
      </svg>
    ),
  },
  error: {
    color: 'bg-red-50 text-red-600',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
      </svg>
    ),
  },
  info: {
    color: 'bg-gray-50 text-gray-600',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a1 1 0 000 2v3a1 1 0 001 1h1a1 1 0 100-2v-3a1 1 0 00-1-1H9z" clipRule="evenodd" />
      </svg>
    ),
  },
  success: {
    color: 'bg-green-50 text-green-600',
    icon: (
      <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
      </svg>
    ),
  },
};

export default function AuditLogPage() {
  return (
    <div>
      {/* Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Audit Log</h1>
        <p className="text-gray-600">Complete history of admin actions and system events</p>
      </div>

      {/* Audit Log List */}
      <div className="space-y-4">
        {auditLogs.map((log) => {
          const iconConfig = iconMap[log.type];
          return (
            <div
              key={log.id}
              className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 hover:shadow-md transition-shadow"
            >
              <div className="flex items-start gap-4">
                {/* Icon */}
                <div className={`w-10 h-10 ${iconConfig.color} rounded-lg flex items-center justify-center flex-shrink-0`}>
                  {iconConfig.icon}
                </div>

                {/* Content */}
                <div className="flex-1 min-w-0">
                  <div className="flex items-start justify-between mb-1">
                    <div>
                      <span className="font-bold text-gray-900">{log.action}</span>
                      <span className="text-gray-600 mx-2">on</span>
                      <span className="text-orange-600 font-medium">{log.target}</span>
                    </div>
                  </div>
                  <p className="text-gray-600 mb-2">{log.description}</p>
                  <div className="flex items-center gap-4 text-sm text-gray-500">
                    <span>{log.user}</span>
                    <span>•</span>
                    <span>{log.timestamp}</span>
                  </div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
