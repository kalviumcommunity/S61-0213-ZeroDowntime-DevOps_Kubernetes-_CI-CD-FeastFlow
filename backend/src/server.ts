import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import fs from 'fs';
import authRoutes from './routes/authRoutes';
import cartRoutes from './routes/cartRoutes';
import dashboardRoutes from './routes/dashboardRoutes';
import networkRoutes from './routes/networkRoutes';
import { query } from './database/db';

// Load env vars
dotenv.config();

const app: Application = express();

const READINESS_BLOCK_FILE = '/tmp/feastflow-readiness-block';
const LIVENESS_FAIL_FILE = '/tmp/feastflow-liveness-fail';

const fileExists = (path: string): boolean => {
  try {
    fs.accessSync(path, fs.constants.F_OK);
    return true;
  } catch {
    return false;
  }
};

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cookie parser
app.use(cookieParser());

// Enable CORS
const allowedOrigins = new Set(['http://localhost:3000', 'http://localhost:3001']);

if (process.env.FRONTEND_URL) {
  process.env.FRONTEND_URL
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean)
    .forEach((origin) => allowedOrigins.add(origin));
}

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.has(origin)) {
      callback(null, true);
      return;
    }

    callback(new Error('CORS origin denied'));
  },
  credentials: true,
}));

// Security headers
app.use(helmet());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/network', networkRoutes);

// Liveness check route - Indicates process health (not dependency health)
app.get('/api/health', async (req: Request, res: Response) => {
  if (fileExists(LIVENESS_FAIL_FILE)) {
    res.status(500).json({
      status: 'unhealthy',
      success: false,
      message: 'Liveness probe is intentionally failing',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      probe: 'liveness',
    });
    return;
  }

  res.status(200).json({
    status: 'healthy',
    success: true,
    message: 'Process is alive',
    timestamp: new Date().toISOString(),
    service: 'feastflow-backend',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    probe: 'liveness',
  });
});

// Readiness check route - Indicates ability to serve traffic safely
app.get('/api/ready', async (req: Request, res: Response) => {
  if (fileExists(READINESS_BLOCK_FILE)) {
    res.status(503).json({
      status: 'not_ready',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      probe: 'readiness',
      reason: 'Readiness is intentionally blocked',
    });
    return;
  }

  try {
    // Verify critical dependency before receiving traffic
    await query('SELECT 1');

    res.status(200).json({
      status: 'ready',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      probe: 'readiness',
      database: 'connected',
    });
  } catch (error) {
    res.status(503).json({
      status: 'not_ready',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      probe: 'readiness',
      error: error instanceof Error ? error.message : 'Unknown error',
      database: 'disconnected',
    });
  }
});

// Runtime status route - Useful for quick operational diagnostics
app.get('/api/status', (req: Request, res: Response) => {
  const toMb = (bytes: number): string => `${(bytes / 1024 / 1024).toFixed(2)} MB`;
  const memoryUsage = process.memoryUsage();

  res.status(200).json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'feastflow-backend',
    version: process.env.APP_VERSION || '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    uptimeSeconds: Number(process.uptime().toFixed(2)),
    uptimeHuman: `${Math.floor(process.uptime() / 60)}m ${Math.floor(process.uptime() % 60)}s`,
    memory: {
      rss: toMb(memoryUsage.rss),
      heapTotal: toMb(memoryUsage.heapTotal),
      heapUsed: toMb(memoryUsage.heapUsed),
      external: toMb(memoryUsage.external),
    },
  });
});

// Root route
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: 'FeastFlow API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      ready: '/api/ready',
      status: '/api/status',
      auth: '/api/auth',
      cart: '/api/cart',
      dashboard: '/api/dashboard',
    },
  });
});

// Ping endpoint - Simple connectivity check
app.get('/api/ping', (req: Request, res: Response) => {
  res.status(200).json({
    message: 'pong',
    timestamp: new Date().toISOString(),
    service: 'feastflow-backend',
  });
});

// Debug endpoint - Returns runtime diagnostics for debugging
app.get('/api/debug', (req: Request, res: Response) => {
  const debugEnabled = process.env.NODE_ENV !== 'production' || process.env.ENABLE_DEBUG_ENDPOINT === 'true';
  if (!debugEnabled) {
    res.status(404).json({
      success: false,
      message: 'Route not found',
    });
    return;
  }

  const memoryUsage = process.memoryUsage();
  res.status(200).json({
    status: 'debug',
    timestamp: new Date().toISOString(),
    service: 'feastflow-backend',
    pid: process.pid,
    platform: process.platform,
    nodeVersion: process.version,
    cwd: process.cwd(),
    uptimeSeconds: Number(process.uptime().toFixed(2)),
    memory: {
      rss: memoryUsage.rss,
      heapTotal: memoryUsage.heapTotal,
      heapUsed: memoryUsage.heapUsed,
      external: memoryUsage.external,
    },
    env: {
      NODE_ENV: process.env.NODE_ENV,
      APP_VERSION: process.env.APP_VERSION,
      FRONTEND_URL: process.env.FRONTEND_URL,
      ...Object.fromEntries(Object.entries(process.env).filter(([k]) => k.startsWith('FEASTFLOW_'))),
    },
  });
});

// 404 handler
app.use((req: Request, res: Response) => {
  res.status(404).json({
    success: false,
    message: 'Route not found',
  });
});

const PORT = process.env.PORT || 5000;

app.listen(PORT, () => {
  console.log(` Server running in ${process.env.NODE_ENV || 'development'} mode on port ${PORT}`);
});

export default app;
