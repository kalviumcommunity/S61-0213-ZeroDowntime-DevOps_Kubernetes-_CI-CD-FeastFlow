import { Response, NextFunction } from 'express';
import { AuthRequest, UserRole } from '../types';

export const authorize = (...roles: UserRole[]) => {
  return (req: AuthRequest, res: Response, next: NextFunction) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated',
      });
    }

    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `User role '${req.user.role}' is not authorized to access this route`,
      });
    }

    next();
  };
};

// Middleware to check if user is admin
export const isAdmin = authorize(UserRole.ADMIN);

// Middleware to check if user is restaurant owner or admin
export const isRestaurantOwnerOrAdmin = authorize(
  UserRole.RESTAURANT_OWNER,
  UserRole.ADMIN
);

// Middleware to check if user is customer, restaurant owner, or admin
export const isAuthenticated = authorize(
  UserRole.CUSTOMER,
  UserRole.RESTAURANT_OWNER,
  UserRole.ADMIN
);
