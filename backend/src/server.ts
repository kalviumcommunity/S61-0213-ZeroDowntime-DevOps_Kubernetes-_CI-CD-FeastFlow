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
const allowedOrigins = ['http://localhost:3000', 'http://localhost:3001'];
if (process.env.FRONTEND_URL) {
  allowedOrigins.push(process.env.FRONTEND_URL);
}

app.use(cors({
  origin: allowedOrigins,
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

// Root route
app.get('/', (req: Request, res: Response) => {
  res.json({
    message: 'FeastFlow API',
    version: '1.0.0',
    endpoints: {
      health: '/api/health',
      auth: '/api/auth',
      cart: '/api/cart',
      dashboard: '/api/dashboard',
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
