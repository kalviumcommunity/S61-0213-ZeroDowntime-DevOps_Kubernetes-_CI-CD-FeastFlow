import { Request, Response } from 'express';
import { query } from '../database/db';
import dns from 'dns';
import { promisify } from 'util';
import http from 'http';

const lookup = promisify(dns.lookup);
const resolve4 = promisify(dns.resolve4);

/**
 * Network Diagnostics Controller
 * Demonstrates Kubernetes DNS-based service discovery and pod-to-service communication
 * 
 * This endpoint proves:
 * 1. DNS resolution works for Kubernetes services
 * 2. Pods can communicate with other services using DNS names
 * 3. Service discovery is automatic (no hardcoded IPs needed)
 */

interface ServiceTest {
  service: string;
  dnsName: string;
  resolved: boolean;
  ipAddress?: string;
  reachable?: boolean;
  responseTime?: number;
  error?: string;
}

interface NetworkDiagnostics {
  timestamp: string;
  podName: string;
  podIP?: string;
  namespace: string;
  tests: ServiceTest[];
  kubernetesServiceDiscovery: {
    explanation: string;
    dnsFormat: string;
    clusterDomain: string;
  };
}

/**
 * Test DNS resolution for a Kubernetes service
 */
async function testDNSResolution(serviceName: string, namespace: string = 'feastflow'): Promise<ServiceTest> {
  const dnsName = `${serviceName}.${namespace}.svc.cluster.local`;
  const test: ServiceTest = {
    service: serviceName,
    dnsName,
    resolved: false,
  };

  try {
    // Try DNS lookup
    const address = await lookup(dnsName);
    test.resolved = true;
    test.ipAddress = address.address;
    
    console.log(`✓ DNS Resolution successful: ${dnsName} -> ${address.address}`);
  } catch (error: any) {
    test.error = error.message;
    console.error(`✗ DNS Resolution failed for ${dnsName}:`, error.message);
  }

  return test;
}

/**
 * Test HTTP connectivity to a service
 */
async function testHTTPConnectivity(hostname: string, port: number, path: string = '/'): Promise<{ reachable: boolean; responseTime: number; error?: string }> {
  return new Promise((resolve) => {
    const startTime = Date.now();
    
    const req = http.request(
      {
        hostname,
        port,
        path,
        method: 'GET',
        timeout: 5000,
      },
      (res) => {
        const responseTime = Date.now() - startTime;
        res.resume(); // Consume response data
        resolve({ reachable: true, responseTime });
      }
    );

    req.on('error', (error) => {
      resolve({ reachable: false, responseTime: Date.now() - startTime, error: error.message });
    });

    req.on('timeout', () => {
      req.destroy();
      resolve({ reachable: false, responseTime: Date.now() - startTime, error: 'Request timeout' });
    });

    req.end();
  });
}

/**
 * Main network diagnostics endpoint
 * GET /api/network/diagnostics
 */
export const getNetworkDiagnostics = async (req: Request, res: Response): Promise<void> => {
  try {
    const diagnostics: NetworkDiagnostics = {
      timestamp: new Date().toISOString(),
      podName: process.env.HOSTNAME || 'unknown',
      namespace: process.env.NAMESPACE || 'feastflow',
      tests: [],
      kubernetesServiceDiscovery: {
        explanation: 'Kubernetes provides automatic DNS-based service discovery. Services are accessible via DNS names instead of hardcoded IPs.',
        dnsFormat: '<service-name>.<namespace>.svc.cluster.local',
        clusterDomain: 'cluster.local',
      },
    };

    console.log('\n=== Running Kubernetes Network Diagnostics ===');
    console.log(`Pod: ${diagnostics.podName}`);
    console.log(`Namespace: ${diagnostics.namespace}`);

    // Test 1: PostgreSQL Service Discovery
    console.log('\n[Test 1] PostgreSQL Service Discovery');
    const postgresTest = await testDNSResolution('postgres', diagnostics.namespace);
    
    // Test PostgreSQL connectivity
    if (postgresTest.resolved) {
      try {
        await query('SELECT 1 as test');
        postgresTest.reachable = true;
        console.log('✓ PostgreSQL is reachable and responding');
      } catch (error: any) {
        postgresTest.reachable = false;
        postgresTest.error = `DNS resolved but connection failed: ${error.message}`;
        console.error('✗ PostgreSQL connection failed:', error.message);
      }
    }
    diagnostics.tests.push(postgresTest);

    // Test 2: Backend Service Discovery (self-discovery)
    console.log('\n[Test 2] Backend Service Discovery (Self)');
    const backendTest = await testDNSResolution('feastflow-backend', diagnostics.namespace);
    
    // Test backend service connectivity
    if (backendTest.resolved && backendTest.ipAddress) {
      const connectivity = await testHTTPConnectivity('feastflow-backend.feastflow.svc.cluster.local', 5000, '/api/health');
      backendTest.reachable = connectivity.reachable;
      backendTest.responseTime = connectivity.responseTime;
      if (!connectivity.reachable) {
        backendTest.error = connectivity.error;
      }
      console.log(`${connectivity.reachable ? '✓' : '✗'} Backend service ${connectivity.reachable ? 'is' : 'is not'} reachable (${connectivity.responseTime}ms)`);
    }
    diagnostics.tests.push(backendTest);

    // Test 3: Frontend Service Discovery (if exists)
    console.log('\n[Test 3] Frontend Service Discovery');
    const frontendTest = await testDNSResolution('feastflow-frontend', diagnostics.namespace);
    
    if (frontendTest.resolved && frontendTest.ipAddress) {
      const connectivity = await testHTTPConnectivity('feastflow-frontend.feastflow.svc.cluster.local', 3000, '/');
      frontendTest.reachable = connectivity.reachable;
      frontendTest.responseTime = connectivity.responseTime;
      if (!connectivity.reachable) {
        frontendTest.error = connectivity.error;
      }
      console.log(`${connectivity.reachable ? '✓' : '✗'} Frontend service ${connectivity.reachable ? 'is' : 'is not'} reachable (${connectivity.responseTime}ms)`);
    }
    diagnostics.tests.push(frontendTest);

    // Test 4: Short-form DNS (within same namespace)
    console.log('\n[Test 4] Short-form DNS Resolution (same namespace)');
    try {
      const shortFormLookup = await lookup('postgres');
      const shortFormTest: ServiceTest = {
        service: 'postgres (short form)',
        dnsName: 'postgres',
        resolved: true,
        ipAddress: shortFormLookup.address,
      };
      diagnostics.tests.push(shortFormTest);
      console.log(`✓ Short-form DNS works: postgres -> ${shortFormLookup.address}`);
    } catch (error: any) {
      diagnostics.tests.push({
        service: 'postgres (short form)',
        dnsName: 'postgres',
        resolved: false,
        error: error.message,
      });
      console.error('✗ Short-form DNS failed:', error.message);
    }

    console.log('\n=== Diagnostics Complete ===\n');

    res.status(200).json({
      success: true,
      message: 'Kubernetes network diagnostics completed',
      diagnostics,
    });
  } catch (error: any) {
    console.error('Network diagnostics error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to run network diagnostics',
      details: error.message,
    });
  }
};

/**
 * Get service discovery information
 * GET /api/network/services
 */
export const getServiceDiscoveryInfo = async (req: Request, res: Response): Promise<void> => {
  try {
    const namespace = process.env.NAMESPACE || 'feastflow';
    
    const serviceInfo = {
      namespace,
      services: [
        {
          name: 'postgres',
          type: 'ClusterIP',
          port: 5432,
          dns: {
            shortForm: 'postgres',
            fqdn: `postgres.${namespace}.svc.cluster.local`,
          },
          purpose: 'PostgreSQL database service - provides persistent data storage',
        },
        {
          name: 'feastflow-backend',
          type: 'ClusterIP',
          port: 5000,
          dns: {
            shortForm: 'feastflow-backend',
            fqdn: `feastflow-backend.${namespace}.svc.cluster.local`,
          },
          purpose: 'Backend API service - handles business logic and data operations',
        },
        {
          name: 'feastflow-frontend',
          type: 'ClusterIP',
          port: 3000,
          dns: {
            shortForm: 'feastflow-frontend',
            fqdn: `feastflow-frontend.${namespace}.svc.cluster.local`,
          },
          purpose: 'Frontend web service - serves the user interface',
        },
      ],
      configuredConnections: {
        'backend → postgres': {
          method: 'DNS-based service discovery',
          host: process.env.DB_HOST || 'postgres',
          port: process.env.DB_PORT || '5432',
          configured: true,
        },
        'frontend → backend': {
          method: 'DNS-based service discovery',
          url: process.env.FRONTEND_URL || 'http://feastflow-backend:5000',
          configured: true,
        },
      },
      kubernetesNetworking: {
        clusterDomain: 'cluster.local',
        dnsService: 'kube-dns / CoreDNS',
        dnsAutomation: 'Kubernetes automatically creates DNS entries for each Service',
        benefits: [
          'No manual IP management required',
          'Services are discoverable by name',
          'Load balancing across multiple pods',
          'Automatic failover and self-healing',
        ],
      },
    };

    res.status(200).json({
      success: true,
      serviceDiscovery: serviceInfo,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      error: 'Failed to get service discovery info',
      details: error.message,
    });
  }
};
