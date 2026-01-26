import React from 'react';
import { usePomodoro } from '../contexts/PomodoroContext';
import { useTasks } from '../contexts/TaskContext';

const PomodoroTimer: React.FC = () => {
  const {
    isRunning,
    timeLeft,
    workDuration,
    breakDuration,
    isWorkTime,
    startTimer,
    pauseTimer,
    resetTimer,
  } = usePomodoro();

  const { tasks } = useTasks();

  const formatTime = (seconds: number): string => {
    const minutes = Math.floor(seconds / 60);
    const remainingSeconds = seconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${remainingSeconds
      .toString()
      .padStart(2, '0')}`;
  };

  const progress = isWorkTime
    ? ((workDuration - timeLeft) / workDuration) * 100
    : ((breakDuration - timeLeft) / breakDuration) * 100;

  return (
    <div className="max-w-2xl mx-auto">
      <div className="bg-white rounded-lg shadow-lg p-8">
        <div className="text-center mb-8">
          <h2 className="text-2xl font-bold text-gray-800 mb-2">
            {isWorkTime ? 'Focus Time' : 'Break Time'}
          </h2>
          <p className="text-gray-600">
            {isWorkTime
              ? 'Stay focused on your current task'
              : 'Take a short break to recharge'}
          </p>
        </div>

        <div className="relative w-64 h-64 mx-auto mb-8">
          <svg className="w-full h-full" viewBox="0 0 100 100">
            {/* Background circle */}
            <circle
              className="text-gray-200"
              strokeWidth="8"
              stroke="currentColor"
              fill="transparent"
              r="44"
              cx="50"
              cy="50"
            />
            {/* Progress circle */}
            <circle
              className={`${
                isWorkTime ? 'text-blue-500' : 'text-green-500'
              } transition-all duration-1000`}
              strokeWidth="8"
              strokeDasharray={`${progress * 2.76} 276`}
              strokeLinecap="round"
              stroke="currentColor"
              fill="transparent"
              r="44"
              cx="50"
              cy="50"
              transform="rotate(-90 50 50)"
            />
          </svg>
          <div className="absolute inset-0 flex items-center justify-center">
            <span className="text-4xl font-bold text-gray-800">
              {formatTime(timeLeft)}
            </span>
          </div>
        </div>

        <div className="flex justify-center space-x-4">
          {!isRunning ? (
            <button
              onClick={startTimer}
              className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors"
            >
              Start
            </button>
          ) : (
            <button
              onClick={pauseTimer}
              className="px-6 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 transition-colors"
            >
              Pause
            </button>
          )}
          <button
            onClick={resetTimer}
            className="px-6 py-2 bg-gray-500 text-white rounded-lg hover:bg-gray-600 transition-colors"
          >
            Reset
          </button>
        </div>

        {isWorkTime && tasks.length > 0 && (
          <div className="mt-8">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">
              Current Task
            </h3>
            <div className="bg-gray-50 rounded-lg p-4">
              <p className="text-gray-800 font-medium">
                {tasks.find((task) => task.status === 'in-progress')?.title ||
                  'No active task'}
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default PomodoroTimer; 