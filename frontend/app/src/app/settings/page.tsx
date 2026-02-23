'use client';

import { useAuth } from '@/context/AuthContext';
import { useEffect, useState } from 'react';
import { useRouter } from 'next/navigation';

export default function SettingsPage() {
  const { user } = useAuth();
  const router = useRouter();
  const [activeSection, setActiveSection] = useState<'account' | 'notifications' | 'privacy' | 'appearance'>('account');
  
  // Account Settings
  const [emailNotifications, setEmailNotifications] = useState(true);
  const [pushNotifications, setPushNotifications] = useState(true);
  const [orderUpdates, setOrderUpdates] = useState(true);
  const [promotions, setPromotions] = useState(true);
  
  // Privacy Settings
  const [showProfile, setShowProfile] = useState(true);
  const [shareData, setShareData] = useState(false);
  
  // Appearance Settings
  const [theme, setTheme] = useState<'light' | 'dark' | 'auto'>('light');

  useEffect(() => {
    if (!user) {
      router.push('/login');
      return;
    }
  }, [user, router]);

  const handleSaveSettings = () => {
    // TODO: Implement API call to save settings
    alert('Settings saved successfully!');
  };

  const handleChangePassword = () => {
    // TODO: Implement change password functionality
    alert('Password change functionality will be implemented with backend API');
  };

  const handleDeleteAccount = () => {
    const confirmed = confirm('Are you sure you want to delete your account? This action cannot be undone.');
    if (confirmed) {
      // TODO: Implement account deletion
      alert('Account deletion functionality will be implemented with backend API');
    }
  };

  if (!user) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-gray-600">Loading...</div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gray-50 py-8">
      <div className="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8">
        {/* Header */}
        <div className="mb-8">
          <button
            onClick={() => router.back()}
            className="flex items-center text-gray-600 hover:text-gray-900 mb-4"
          >
            <svg className="w-5 h-5 mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
            Back
          </button>
          <h1 className="text-3xl font-bold text-gray-900">Settings</h1>
          <p className="text-gray-600 mt-2">Manage your account preferences</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
          {/* Sidebar Navigation */}
          <div className="md:col-span-1">
            <nav className="bg-white rounded-lg shadow-sm border border-gray-200 p-2">
              <button
                onClick={() => setActiveSection('account')}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  activeSection === 'account'
                    ? 'bg-orange-50 text-orange-600'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                </svg>
                Account
              </button>

              <button
                onClick={() => setActiveSection('notifications')}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  activeSection === 'notifications'
                    ? 'bg-orange-50 text-orange-600'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
                </svg>
                Notifications
              </button>

              <button
                onClick={() => setActiveSection('privacy')}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  activeSection === 'privacy'
                    ? 'bg-orange-50 text-orange-600'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z" />
                </svg>
                Privacy
              </button>

              <button
                onClick={() => setActiveSection('appearance')}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  activeSection === 'appearance'
                    ? 'bg-orange-50 text-orange-600'
                    : 'text-gray-700 hover:bg-gray-50'
                }`}
              >
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01" />
                </svg>
                Appearance
              </button>
            </nav>
          </div>

          {/* Content Area */}
          <div className="md:col-span-3">
            <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
              {/* Account Settings */}
              {activeSection === 'account' && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Account Settings</h2>
                  
                  <div className="space-y-6">
                    {/* Email */}
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Email Address
                      </label>
                      <input
                        type="email"
                        value={user.email}
                        disabled
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-50 text-gray-500 cursor-not-allowed"
                      />
                      <p className="text-xs text-gray-500 mt-1">Your email cannot be changed</p>
                    </div>

                    {/* Change Password */}
                    <div className="border-t border-gray-200 pt-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">Password</h3>
                      <button
                        onClick={handleChangePassword}
                        className="px-4 py-2 text-sm font-medium text-white bg-orange-500 rounded-lg hover:bg-orange-600 transition-colors"
                      >
                        Change Password
                      </button>
                    </div>

                    {/* Delete Account */}
                    <div className="border-t border-gray-200 pt-6">
                      <h3 className="text-lg font-semibold text-red-600 mb-2">Danger Zone</h3>
                      <p className="text-sm text-gray-600 mb-4">
                        Once you delete your account, there is no going back. Please be certain.
                      </p>
                      <button
                        onClick={handleDeleteAccount}
                        className="px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-lg hover:bg-red-700 transition-colors"
                      >
                        Delete Account
                      </button>
                    </div>
                  </div>
                </div>
              )}

              {/* Notification Settings */}
              {activeSection === 'notifications' && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Notification Preferences</h2>
                  
                  <div className="space-y-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">Email Notifications</p>
                        <p className="text-sm text-gray-600">Receive notifications via email</p>
                      </div>
                      <button
                        onClick={() => setEmailNotifications(!emailNotifications)}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          emailNotifications ? 'bg-orange-500' : 'bg-gray-200'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            emailNotifications ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">Push Notifications</p>
                        <p className="text-sm text-gray-600">Receive push notifications on your device</p>
                      </div>
                      <button
                        onClick={() => setPushNotifications(!pushNotifications)}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          pushNotifications ? 'bg-orange-500' : 'bg-gray-200'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            pushNotifications ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <div className="border-t border-gray-200 pt-6">
                      <h3 className="text-lg font-semibold text-gray-900 mb-4">Notification Types</h3>
                      
                      <div className="space-y-4">
                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-medium text-gray-900">Order Updates</p>
                            <p className="text-sm text-gray-600">Get notified about your order status</p>
                          </div>
                          <button
                            onClick={() => setOrderUpdates(!orderUpdates)}
                            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                              orderUpdates ? 'bg-orange-500' : 'bg-gray-200'
                            }`}
                          >
                            <span
                              className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                orderUpdates ? 'translate-x-6' : 'translate-x-1'
                              }`}
                            />
                          </button>
                        </div>

                        <div className="flex items-center justify-between">
                          <div>
                            <p className="font-medium text-gray-900">Promotions & Offers</p>
                            <p className="text-sm text-gray-600">Receive special deals and discounts</p>
                          </div>
                          <button
                            onClick={() => setPromotions(!promotions)}
                            className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                              promotions ? 'bg-orange-500' : 'bg-gray-200'
                            }`}
                          >
                            <span
                              className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                                promotions ? 'translate-x-6' : 'translate-x-1'
                              }`}
                            />
                          </button>
                        </div>
                      </div>
                    </div>

                    <button
                      onClick={handleSaveSettings}
                      className="w-full px-4 py-2 text-sm font-medium text-white bg-orange-500 rounded-lg hover:bg-orange-600 transition-colors"
                    >
                      Save Preferences
                    </button>
                  </div>
                </div>
              )}

              {/* Privacy Settings */}
              {activeSection === 'privacy' && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Privacy Settings</h2>
                  
                  <div className="space-y-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">Public Profile</p>
                        <p className="text-sm text-gray-600">Make your profile visible to others</p>
                      </div>
                      <button
                        onClick={() => setShowProfile(!showProfile)}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          showProfile ? 'bg-orange-500' : 'bg-gray-200'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            showProfile ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <div className="flex items-center justify-between">
                      <div>
                        <p className="font-medium text-gray-900">Data Sharing</p>
                        <p className="text-sm text-gray-600">Share usage data to improve services</p>
                      </div>
                      <button
                        onClick={() => setShareData(!shareData)}
                        className={`relative inline-flex h-6 w-11 items-center rounded-full transition-colors ${
                          shareData ? 'bg-orange-500' : 'bg-gray-200'
                        }`}
                      >
                        <span
                          className={`inline-block h-4 w-4 transform rounded-full bg-white transition-transform ${
                            shareData ? 'translate-x-6' : 'translate-x-1'
                          }`}
                        />
                      </button>
                    </div>

                    <button
                      onClick={handleSaveSettings}
                      className="w-full px-4 py-2 text-sm font-medium text-white bg-orange-500 rounded-lg hover:bg-orange-600 transition-colors"
                    >
                      Save Privacy Settings
                    </button>
                  </div>
                </div>
              )}

              {/* Appearance Settings */}
              {activeSection === 'appearance' && (
                <div>
                  <h2 className="text-xl font-bold text-gray-900 mb-6">Appearance</h2>
                  
                  <div className="space-y-6">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-4">
                        Theme Preference
                      </label>
                      <div className="grid grid-cols-3 gap-4">
                        <button
                          onClick={() => setTheme('light')}
                          className={`p-4 border-2 rounded-lg transition-colors ${
                            theme === 'light'
                              ? 'border-orange-500 bg-orange-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <svg className="w-8 h-8 mx-auto mb-2 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                          </svg>
                          <p className="text-sm font-medium text-gray-900">Light</p>
                        </button>

                        <button
                          onClick={() => setTheme('dark')}
                          className={`p-4 border-2 rounded-lg transition-colors ${
                            theme === 'dark'
                              ? 'border-orange-500 bg-orange-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <svg className="w-8 h-8 mx-auto mb-2 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                          </svg>
                          <p className="text-sm font-medium text-gray-900">Dark</p>
                        </button>

                        <button
                          onClick={() => setTheme('auto')}
                          className={`p-4 border-2 rounded-lg transition-colors ${
                            theme === 'auto'
                              ? 'border-orange-500 bg-orange-50'
                              : 'border-gray-200 hover:border-gray-300'
                          }`}
                        >
                          <svg className="w-8 h-8 mx-auto mb-2 text-gray-700" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
                          </svg>
                          <p className="text-sm font-medium text-gray-900">Auto</p>
                        </button>
                      </div>
                      <p className="text-xs text-gray-500 mt-2">
                        {theme === 'auto' && 'Theme will automatically match your system preference'}
                      </p>
                    </div>

                    <button
                      onClick={handleSaveSettings}
                      className="w-full px-4 py-2 text-sm font-medium text-white bg-orange-500 rounded-lg hover:bg-orange-600 transition-colors"
                    >
                      Save Appearance Settings
                    </button>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
