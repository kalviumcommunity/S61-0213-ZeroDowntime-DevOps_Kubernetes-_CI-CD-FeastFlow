import express from 'express';
import {
  getDashboardMetrics,
  getSystemHealth,
  getRecentActivity,
} from '../controllers/dashboardController';
import { protect } from '../middleware/auth';

const router = express.Router();

// All dashboard routes require authentication
router.use(protect);

// Get dashboard metrics
router.get('/metrics', getDashboardMetrics);

// Get system health
router.get('/health', getSystemHealth);

// Get recent activity
router.get('/activity', getRecentActivity);

export default router;
