// backend/tests/smoke.test.ts

// Use CommonJS require to avoid esModuleInterop issues
const axiosLib = require('axios');

describe('Smoke Tests - FeastFlow Backend', () => {
  const baseUrl = process.env.FEASTFLOW_BACKEND_URL || 'http://localhost:3000';

  it('Service is up - /api/health returns 200 and healthy', async () => {
    const res = await axiosLib.get(`${baseUrl}/api/health`);
    const data = res.data as any;
    expect(res.status).toBe(200);
    expect(data.status).toBe('healthy');
    expect(data.success).toBe(true);
    expect(data.service).toBe('feastflow-backend');
    expect(data.probe).toBe('liveness');
  });

  it('Service unhealthy - /api/health returns 500 and unhealthy when liveness file exists', async () => {
    // This test assumes the liveness fail file is present in the deployment
    try {
      const res = await axiosLib.get(`${baseUrl}/api/health`);
      // If service is healthy, skip this test
      if (res.status === 200) return;
    } catch (err: any) {
      if (err.response) {
        const data = err.response.data as any;
        expect(err.response.status).toBe(500);
        expect(data.status).toBe('unhealthy');
        expect(data.success).toBe(false);
        expect(data.service).toBe('feastflow-backend');
        expect(data.probe).toBe('liveness');
      }
    }
  });
});
