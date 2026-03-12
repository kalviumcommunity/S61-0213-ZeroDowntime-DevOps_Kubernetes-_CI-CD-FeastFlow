import { Request, Response } from 'express';
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { query } from '../database/db';
import { RegisterDTO, LoginDTO, UserRole, AuthRequest } from '../types';

const getJwtSecret = (): string => {
  const secret = process.env.JWT_SECRET;
  if (!secret || secret.trim().length < 16) {
    throw new Error('JWT_SECRET is missing or too weak');
  }
  return secret;
};

const normalizeEmail = (email: string): string => email.trim().toLowerCase();

// Generate JWT Token
const generateToken = (id: string, email: string, role: UserRole): string => {
  const payload = { id, email, role };
  const expire = process.env.JWT_EXPIRE || '7d';
  
  return jwt.sign(payload, getJwtSecret(), { expiresIn: expire as any });
};

// Send token response
const sendTokenResponse = (
  user: any,
  statusCode: number,
  res: Response
) => {
  const token = generateToken(user.id, user.email, user.role);

  const options = {
    expires: new Date(
      Date.now() + (parseInt(process.env.JWT_COOKIE_EXPIRE || '7') * 24 * 60 * 60 * 1000)
    ),
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: process.env.NODE_ENV === 'production' ? ('none' as const) : ('lax' as const),
  };

  res
    .status(statusCode)
    .cookie('token', token, options)
    .json({
      success: true,
      token,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        phoneNumber: user.phone_number,
      },
    });
};

// @desc    Register user
// @route   POST /api/auth/register
// @access  Public
export const register = async (req: Request, res: Response) => {
  try {
    const { email, password, firstName, lastName, phoneNumber, role }: RegisterDTO = req.body;

    if (typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or password format',
      });
    }

    const normalizedEmail = normalizeEmail(email);

    // Validation
    if (!normalizedEmail || !password || !firstName || !lastName) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields',
      });
    }

    if (password.length < 8) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 8 characters long',
      });
    }

    // Check if user exists
    const userExists = await query('SELECT * FROM users WHERE email = $1', [normalizedEmail]);

    if (userExists.rows.length > 0) {
      return res.status(400).json({
        success: false,
        message: 'User already exists with this email',
      });
    }

    // Hash password
    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    // Block privilege escalation from public registration flow.
    const userRole = UserRole.CUSTOMER;
    if (role && role !== UserRole.CUSTOMER) {
      return res.status(403).json({
        success: false,
        message: 'Registration with elevated roles is not allowed',
      });
    }

    const result = await query(
      `INSERT INTO users (email, password, first_name, last_name, role, phone_number)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [normalizedEmail, hashedPassword, firstName, lastName, userRole, phoneNumber || null]
    );

    const user = result.rows[0];
    sendTokenResponse(user, 201, res);
  } catch (error) {
    console.error('Register error:', error);
    res.status(500).json({
      success: false,
      message: 'Error creating user',
    });
  }
};

// @desc    Login user
// @route   POST /api/auth/login
// @access  Public
export const login = async (req: Request, res: Response) => {
  try {
    const { email, password }: LoginDTO = req.body;

    if (typeof email !== 'string' || typeof password !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'Invalid email or password format',
      });
    }

    const normalizedEmail = normalizeEmail(email);

    // Validation
    if (!normalizedEmail || !password) {
      return res.status(400).json({
        success: false,
        message: 'Please provide email and password',
      });
    }

    // Check for user
    const result = await query(
      'SELECT * FROM users WHERE email = $1 AND is_active = true',
      [normalizedEmail]
    );

    if (result.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const user = result.rows[0];

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);

    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    sendTokenResponse(user, 200, res);
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Error logging in',
    });
  }
};

// @desc    Get current logged in user
// @route   GET /api/auth/me
// @access  Private
export const getMe = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Not authenticated',
      });
    }

    const result = await query(
      'SELECT id, email, first_name, last_name, role, phone_number, created_at FROM users WHERE id = $1',
      [req.user.id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'User not found',
      });
    }

    const user = result.rows[0];

    res.status(200).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        firstName: user.first_name,
        lastName: user.last_name,
        role: user.role,
        phoneNumber: user.phone_number,
        createdAt: user.created_at,
      },
    });
  } catch (error) {
    console.error('GetMe error:', error);
    res.status(500).json({
      success: false,
      message: 'Error fetching user data',
    });
  }
};

// @desc    Logout user / clear cookie
// @route   POST /api/auth/logout
// @access  Private
export const logout = async (req: Request, res: Response) => {
  res.cookie('token', 'none', {
    expires: new Date(Date.now() + 10 * 1000),
    httpOnly: true,
  });

  res.status(200).json({
    success: true,
    message: 'User logged out successfully',
  });
};
