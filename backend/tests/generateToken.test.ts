// backend/tests/generateToken.test.ts

import { describe, it, expect } from '@jest/globals';
const jwt = require('jsonwebtoken');
const { generateToken } = require('../src/controllers/authController');

describe('generateToken', () => {
  const OLD_ENV = process.env;
  beforeAll(() => {
    process.env = { ...OLD_ENV, JWT_SECRET: 'supersecretkeyforjwt1234', JWT_EXPIRE: '1h' };
  });
  afterAll(() => {
    process.env = OLD_ENV;
  });

  it('should generate a valid JWT token', () => {
    const id = 'user123';
    const email = 'test@example.com';
    const role = 'admin';
    const token = generateToken(id, email, role);
    expect(typeof token).toBe('string');
    const decoded = jwt.verify(token, process.env.JWT_SECRET!);
    expect((decoded as any).id).toBe(id);
    expect((decoded as any).email).toBe(email);
    expect((decoded as any).role).toBe(role);
  });
});
