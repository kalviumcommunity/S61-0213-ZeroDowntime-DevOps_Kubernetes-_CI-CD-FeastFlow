import express, { Application, Request, Response } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import cookieParser from 'cookie-parser';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes';
import cartRoutes from './routes/cartRoutes';
import dashboardRoutes from './routes/dashboardRoutes';
import { query } from './database/db';

// Load env vars
dotenv.config();

const app: Application = express();

// Body parser
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Cookie parser
app.use(cookieParser());

// Enable CORS
app.use(cors({
  origin: process.env.FRONTEND_URL || 'http://localhost:3000',
  credentials: true,
}));

// Security headers
app.use(helmet());

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/dashboard', dashboardRoutes);

// Health check route - For Kubernetes liveness and readiness probes
app.get('/api/health', async (req: Request, res: Response) => {
  try {
    // Check database connectivity
    await query('SELECT 1');
    
    res.status(200).json({
      status: 'healthy',
      success: true,
      message: 'Server is running',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      version: process.env.APP_VERSION || '1.0.0',
      environment: process.env.NODE_ENV || 'development',
      database: 'connected',
    });
  } catch (error) {
    console.error('Health check failed:', error);
    res.status(503).json({
      status: 'unhealthy',
      success: false,
      message: 'Service unavailable',
      timestamp: new Date().toISOString(),
      service: 'feastflow-backend',
      error: error instanceof Error ? error.message : 'Unknown error',
      database: 'disconnected',
    });
  }
});

// Readiness check route - Kubernetes can use this to determine if pod is ready
app.get('/api/ready', async (req: Request, res: Response) => {
  try {
    // Check if application is ready to serve requests
    await query('SELECT 1');
    
    res.status(200).json({
      status: 'ready',
      timestamp: new Date().toISOString(),
    });
  } catch (error) {
    res.status(503).json({
      status: 'not_ready',
      timestamp: new Date().toISOString(),
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
