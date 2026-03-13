// Time controller
import { Request, Response } from 'express';

export const getTime = (req: Request, res: Response) => {
  res.status(200).json({
    serverTime: new Date().toISOString(),
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone
  });
};