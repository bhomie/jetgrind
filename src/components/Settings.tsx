import React from 'react';
import { usePomodoro } from '../contexts/PomodoroContext';

const Settings: React.FC = () => {
  const {
    workDuration,
    breakDuration,
    setWorkDuration,
    setBreakDuration,
  } = usePomodoro();

  const handleWorkDurationChange = (minutes: number) => {
    setWorkDuration(minutes * 60);
  };

  const handleBreakDurationChange = (minutes: number) => {
    setBreakDuration(minutes * 60);
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-lg shadow-lg p-8">
        <h2 className="text-2xl font-bold text-gray-800 mb-6">Settings</h2>

        <div className="space-y-6">
          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-4">
              Pomodoro Timer
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Work Duration (minutes)
                </label>
                <input
                  type="number"
                  min="1"
                  max="60"
                  value={workDuration / 60}
                  onChange={(e) =>
                    handleWorkDurationChange(parseInt(e.target.value))
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Break Duration (minutes)
                </label>
                <input
                  type="number"
                  min="1"
                  max="30"
                  value={breakDuration / 60}
                  onChange={(e) =>
                    handleBreakDurationChange(parseInt(e.target.value))
                  }
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500"
                />
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-4">
              Notifications
            </h3>
            <div className="space-y-4">
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="sound-notifications"
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label
                  htmlFor="sound-notifications"
                  className="ml-2 block text-sm text-gray-700"
                >
                  Enable sound notifications
                </label>
              </div>
              <div className="flex items-center">
                <input
                  type="checkbox"
                  id="desktop-notifications"
                  className="h-4 w-4 text-blue-600 focus:ring-blue-500 border-gray-300 rounded"
                />
                <label
                  htmlFor="desktop-notifications"
                  className="ml-2 block text-sm text-gray-700"
                >
                  Enable desktop notifications
                </label>
              </div>
            </div>
          </div>

          <div>
            <h3 className="text-lg font-semibold text-gray-800 mb-4">
              Appearance
            </h3>
            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Theme
                </label>
                <select className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                  <option value="light">Light</option>
                  <option value="dark">Dark</option>
                  <option value="system">System</option>
                </select>
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700">
                  Accent Color
                </label>
                <select className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500">
                  <option value="blue">Blue</option>
                  <option value="purple">Purple</option>
                  <option value="green">Green</option>
                  <option value="orange">Orange</option>
                </select>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Settings; 