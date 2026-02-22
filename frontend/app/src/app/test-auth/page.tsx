'use client';

import { useAuth } from '@/context/AuthContext';
import { useEffect, useState } from 'react';
import Link from 'next/link';

export default function TestAuthPage() {
  const { user, loading, login, register, logout } = useAuth();
  const [status, setStatus] = useState<string>('');
  const [apiHealth, setApiHealth] = useState<string>('Checking...');

  useEffect(() => {
    // Test API connection
    fetch('http://localhost:5000/api/health')
      .then(res => res.json())
      .then(data => setApiHealth(data.success ? '✅ Connected' : '❌ Failed'))
      .catch(() => setApiHealth('❌ Backend not running'));
  }, []);

  const testRegister = async () => {
    setStatus('Testing registration...');
    const testUser = {
      email: `test${Date.now()}@example.com`,
      password: 'Test123!',
      firstName: 'Test',
      lastName: 'User',
      phoneNumber: '+1234567890',
    };
    
    const result = await register(testUser);
    setStatus(result.success ? '✅ Registration successful!' : `❌ ${result.message}`);
  };

  const testLogin = async () => {
    setStatus('Testing login...');
    const result = await login({
      email: 'admin@feastflow.com',
      password: 'Admin@123',
    });
    setStatus(result.success ? '✅ Login successful!' : `❌ ${result.message}`);
  };

  const testLogout = async () => {
    setStatus('Testing logout...');
    await logout();
    setStatus('✅ Logout successful!');
  };

  if (loading) {
    return (
      <div className="min-h-screen bg-gray-50 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-orange-500 mx-auto mb-4"></div>
          <p className="text-gray-600">Loading...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="bg-white rounded-2xl shadow-sm border border-gray-200 p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">
            🧪 Authentication Test Dashboard
          </h1>
          <p className="text-gray-600 mb-8">Test the backend integration</p>

          {/* API Status */}
          <div className="mb-8 p-4 bg-gray-50 rounded-lg">
            <h2 className="font-semibold text-gray-900 mb-2">Backend API Status</h2>
            <p className="text-lg">{apiHealth}</p>
            <p className="text-sm text-gray-600 mt-1">http://localhost:5000/api</p>
          </div>

          {/* User Status */}
          <div className="mb-8 p-4 bg-blue-50 rounded-lg">
            <h2 className="font-semibold text-gray-900 mb-2">Current User Status</h2>
            {user ? (
              <div>
                <p className="text-green-600 font-semibold mb-2">✅ Authenticated</p>
                <div className="bg-white rounded p-3 text-sm">
                  <p><strong>ID:</strong> {user.id}</p>
                  <p><strong>Email:</strong> {user.email}</p>
                  <p><strong>Name:</strong> {user.firstName} {user.lastName}</p>
                  <p><strong>Role:</strong> {user.role}</p>
                  {user.phoneNumber && <p><strong>Phone:</strong> {user.phoneNumber}</p>}
                </div>
              </div>
            ) : (
              <p className="text-red-600 font-semibold">❌ Not authenticated</p>
            )}
          </div>

          {/* Test Actions */}
          <div className="mb-8">
            <h2 className="font-semibold text-gray-900 mb-4">Test Actions</h2>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <button
                onClick={testRegister}
                disabled={!!user}
                className="px-6 py-3 bg-green-500 text-white rounded-lg font-semibold hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Test Register
              </button>
              
              <button
                onClick={testLogin}
                disabled={!!user}
                className="px-6 py-3 bg-blue-500 text-white rounded-lg font-semibold hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Test Login (Admin)
              </button>
              
              <button
                onClick={testLogout}
                disabled={!user}
                className="px-6 py-3 bg-red-500 text-white rounded-lg font-semibold hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                Test Logout
              </button>
            </div>
          </div>

          {/* Status Message */}
          {status && (
            <div className="mb-8 p-4 bg-yellow-50 border border-yellow-200 rounded-lg">
              <p className="text-gray-900">{status}</p>
            </div>
          )}

          {/* Quick Links */}
          <div className="border-t pt-6">
            <h2 className="font-semibold text-gray-900 mb-4">Quick Links</h2>
            <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
              <Link
                href="/login"
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                Login Page
              </Link>
              <Link
                href="/signup"
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                Signup Page
              </Link>
              <Link
                href="/"
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                Home
              </Link>
              <Link
                href="/admin"
                className="px-4 py-2 bg-gray-100 text-gray-700 rounded-lg text-center hover:bg-gray-200 transition-colors"
              >
                Admin
              </Link>
            </div>
          </div>

          {/* Test Credentials */}
          <div className="border-t pt-6 mt-6">
            <h2 className="font-semibold text-gray-900 mb-4">Test Credentials</h2>
            <div className="bg-gray-50 rounded-lg p-4 font-mono text-sm">
              <p className="mb-2"><strong>Admin Account:</strong></p>
              <p>Email: admin@feastflow.com</p>
              <p>Password: Admin@123</p>
            </div>
          </div>

          {/* API Endpoints */}
          <div className="border-t pt-6 mt-6">
            <h2 className="font-semibold text-gray-900 mb-4">API Endpoints</h2>
            <div className="space-y-2 text-sm font-mono">
              <div className="flex items-center gap-2">
                <span className="px-2 py-1 bg-green-100 text-green-700 rounded font-semibold">POST</span>
                <span>/api/auth/register</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2 py-1 bg-blue-100 text-blue-700 rounded font-semibold">POST</span>
                <span>/api/auth/login</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2 py-1 bg-purple-100 text-purple-700 rounded font-semibold">GET</span>
                <span>/api/auth/me</span>
              </div>
              <div className="flex items-center gap-2">
                <span className="px-2 py-1 bg-red-100 text-red-700 rounded font-semibold">POST</span>
                <span>/api/auth/logout</span>
              </div>
            </div>
          </div>
        </div>

        {/* Instructions */}
        <div className="mt-8 bg-blue-50 border border-blue-200 rounded-xl p-6">
          <h3 className="font-bold text-blue-900 mb-3">📝 Instructions</h3>
          <ol className="list-decimal list-inside space-y-2 text-blue-900">
            <li>Make sure backend is running on <code className="bg-white px-2 py-1 rounded">http://localhost:5000</code></li>
            <li>Check that "Backend API Status" shows "✅ Connected"</li>
            <li>Click "Test Register" to create a new user (only works when logged out)</li>
            <li>Click "Test Login (Admin)" to login with the default admin account</li>
            <li>Check that "Current User Status" shows your user details</li>
            <li>Click "Test Logout" to logout</li>
            <li>Try the actual Login and Signup pages using the Quick Links</li>
          </ol>
        </div>
      </div>
    </div>
  );
}
