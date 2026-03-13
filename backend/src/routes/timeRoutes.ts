// Time route
import { Router } from 'express';
import { getTime } from '../controllers/timeController';

const router = Router();

router.get('/time', getTime);

export default router;
