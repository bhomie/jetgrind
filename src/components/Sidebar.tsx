import React from 'react';
import { Link, useLocation } from 'react-router-dom';
import {
  ClipboardDocumentListIcon,
  ClockIcon,
  Cog6ToothIcon,
  ChartBarIcon,
} from '@heroicons/react/24/outline';

const Sidebar: React.FC = () => {
  const location = useLocation();

  const isActive = (path: string) => location.pathname === path;

  const navItems = [
    {
      name: 'Tasks',
      path: '/',
      icon: ClipboardDocumentListIcon,
    },
    {
      name: 'Pomodoro',
      path: '/pomodoro',
      icon: ClockIcon,
    },
    {
      name: 'Statistics',
      path: '/statistics',
      icon: ChartBarIcon,
    },
    {
      name: 'Settings',
      path: '/settings',
      icon: Cog6ToothIcon,
    },
  ];

  return (
    <div className="w-64 bg-white border-r border-gray-200 h-screen">
      <div className="p-6">
        <h1 className="text-2xl font-bold text-blue-600">JetSet</h1>
        <p className="text-sm text-gray-500 mt-1">ADHD Task Manager</p>
      </div>

      <nav className="mt-6">
        <div className="px-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <Link
                key={item.path}
                to={item.path}
                className={`flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors ${
                  isActive(item.path)
                    ? 'bg-blue-50 text-blue-600'
                    : 'text-gray-600 hover:bg-gray-50'
                }`}
              >
                <Icon className="w-5 h-5 mr-3" />
                {item.name}
              </Link>
            );
          })}
        </div>
      </nav>

      <div className="absolute bottom-0 w-64 p-4 border-t border-gray-200">
        <div className="flex items-center space-x-3">
          <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center">
            <span className="text-blue-600 font-medium">JS</span>
          </div>
          <div>
            <p className="text-sm font-medium text-gray-700">JetSet User</p>
            <p className="text-xs text-gray-500">Free Plan</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Sidebar; 