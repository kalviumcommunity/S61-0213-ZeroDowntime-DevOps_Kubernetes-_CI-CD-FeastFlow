import express from 'express';
import { getNetworkDiagnostics, getServiceDiscoveryInfo } from '../controllers/networkController';

const router = express.Router();

/**
 * Network Diagnostics Routes
 * 
 * These routes demonstrate Kubernetes networking and service discovery
 * for Sprint #3 submission
 */

// GET /api/network/diagnostics - Run comprehensive network tests
router.get('/diagnostics', getNetworkDiagnostics);

// GET /api/network/services - Get service discovery information
router.get('/services', getServiceDiscoveryInfo);

export default router;
