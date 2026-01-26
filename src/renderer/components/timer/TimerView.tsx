import { useEffect, useState, useCallback } from 'react';
import { Play, Pause, Square, SkipForward, Settings, Link2, X } from 'lucide-react';
import { useTimerStore } from '../../stores/timerStore';
import { useTaskStore } from '../../stores/taskStore';
import { useUserStore } from '../../stores/userStore';
import { useToastStore } from '../../stores/toastStore';
import { TimerSettingsModal } from './TimerSettingsModal';
import { playTimerComplete, playTimerStart, initAudio } from '../../utils/sounds';
import { cn } from '../../utils/cn';
import { XP_REWARDS, COIN_REWARDS } from '../../../shared/types';

export function TimerView() {
  const {
    state,
    phase,
    timeRemaining,
    totalTime,
    completedPomodoros,
    linkedTaskId,
    settings,
    init,
    start,
    pause,
    resume,
    stop,
    skipToBreak,
    skipToWork,
    updateSettings,
  } = useTimerStore();

  const { tasks, init: initTasks } = useTaskStore();
  const { refresh: refreshUser } = useUserStore();
  const { showReward } = useToastStore();

  const [showSettings, setShowSettings] = useState(false);
  const [showTaskSelector, setShowTaskSelector] = useState(false);
  const [selectedTaskId, setSelectedTaskId] = useState<string | null>(null);
  const [prevState, setPrevState] = useState(state);
  const [prevCompletedPomodoros, setPrevCompletedPomodoros] = useState(completedPomodoros);

  useEffect(() => {
    init();
    initTasks();
    initAudio();
  }, [init, initTasks]);

  // Handle timer completion - show rewards
  useEffect(() => {
    if (
      prevState === 'running' &&
      (state === 'completed' || state === 'running') &&
      completedPomodoros > prevCompletedPomodoros &&
      phase !== 'work' // We just finished a work session and moved to break
    ) {
      // Play completion sound
      if (settings.soundEnabled) {
        playTimerComplete();
      }

      // Show reward toast
      showReward(XP_REWARDS.pomodoro, COIN_REWARDS.pomodoro, 'Pomodoro Complete!');
      refreshUser();
    }

    setPrevState(state);
    setPrevCompletedPomodoros(completedPomodoros);
  }, [state, completedPomodoros, phase, prevState, prevCompletedPomodoros, settings.soundEnabled, showReward, refreshUser]);

  const handleStart = useCallback(() => {
    if (settings.soundEnabled) {
      playTimerStart();
    }
    start(selectedTaskId || undefined);
  }, [start, selectedTaskId, settings.soundEnabled]);

  const handleStop = useCallback(() => {
    stop();
    setSelectedTaskId(null);
  }, [stop]);

  const handleSelectTask = (taskId: string | null) => {
    setSelectedTaskId(taskId);
    setShowTaskSelector(false);
  };

  const minutes = Math.floor(timeRemaining / 60);
  const seconds = timeRemaining % 60;
  const progress = ((totalTime - timeRemaining) / totalTime) * 100;

  const phaseLabels = {
    work: 'Focus Time',
    short_break: 'Short Break',
    long_break: 'Long Break',
  };

  const phaseColors = {
    work: {
      gradient: 'from-primary-400 to-primary-500',
      bg: 'bg-primary-100',
      text: 'text-primary-700',
      stroke: 'text-primary-500',
    },
    short_break: {
      gradient: 'from-green-400 to-green-500',
      bg: 'bg-green-100',
      text: 'text-green-700',
      stroke: 'text-green-500',
    },
    long_break: {
      gradient: 'from-blue-400 to-blue-500',
      bg: 'bg-blue-100',
      text: 'text-blue-700',
      stroke: 'text-blue-500',
    },
  };

  const colors = phaseColors[phase];
  const pendingTasks = tasks.filter((t) => t.status !== 'completed' && !t.parentId);
  const linkedTask = tasks.find((t) => t.id === (linkedTaskId || selectedTaskId));

  return (
    <div className="max-w-lg mx-auto">
      <h1 className="text-2xl font-bold text-gray-800 text-center mb-8">Pomodoro Timer</h1>

      {/* Timer Circle */}
      <div className="relative w-72 h-72 mx-auto mb-8">
        {/* Background Circle */}
        <svg className="w-full h-full transform -rotate-90">
          <circle
            cx="144"
            cy="144"
            r="136"
            stroke="currentColor"
            strokeWidth="16"
            fill="none"
            className="text-gray-100"
          />
          <circle
            cx="144"
            cy="144"
            r="136"
            stroke="currentColor"
            strokeWidth="16"
            fill="none"
            strokeLinecap="round"
            strokeDasharray={`${2 * Math.PI * 136}`}
            strokeDashoffset={`${2 * Math.PI * 136 * (1 - progress / 100)}`}
            className={cn('transition-all duration-1000 ease-linear', colors.stroke)}
          />
        </svg>

        {/* Timer Display */}
        <div className="absolute inset-0 flex flex-col items-center justify-center">
          <span
            className={cn('text-sm font-medium mb-2 px-3 py-1 rounded-full', colors.bg, colors.text)}
          >
            {phaseLabels[phase]}
          </span>
          <span className="text-6xl font-bold text-gray-800 tabular-nums">
            {String(minutes).padStart(2, '0')}:{String(seconds).padStart(2, '0')}
          </span>
          {linkedTask && (
            <span className="text-sm text-gray-500 mt-2 flex items-center gap-1">
              <Link2 className="w-3 h-3" />
              {linkedTask.title.slice(0, 20)}
              {linkedTask.title.length > 20 ? '...' : ''}
            </span>
          )}
        </div>
      </div>

      {/* Task Selector (when idle) */}
      {(state === 'idle' || state === 'completed') && phase === 'work' && (
        <div className="mb-6">
          {showTaskSelector ? (
            <div className="kawaii-card animate-slide-up">
              <div className="flex items-center justify-between mb-3">
                <span className="text-sm font-medium text-gray-700">Link to task (optional)</span>
                <button
                  onClick={() => setShowTaskSelector(false)}
                  className="p-1 text-gray-400 hover:text-gray-600"
                >
                  <X className="w-4 h-4" />
                </button>
              </div>
              <div className="space-y-2 max-h-48 overflow-y-auto">
                <button
                  onClick={() => handleSelectTask(null)}
                  className={cn(
                    'w-full text-left px-3 py-2 rounded-xl text-sm transition-colors',
                    !selectedTaskId ? 'bg-primary-100 text-primary-700' : 'hover:bg-gray-100'
                  )}
                >
                  No linked task
                </button>
                {pendingTasks.map((task) => (
                  <button
                    key={task.id}
                    onClick={() => handleSelectTask(task.id)}
                    className={cn(
                      'w-full text-left px-3 py-2 rounded-xl text-sm transition-colors',
                      selectedTaskId === task.id
                        ? 'bg-primary-100 text-primary-700'
                        : 'hover:bg-gray-100'
                    )}
                  >
                    {task.title}
                  </button>
                ))}
                {pendingTasks.length === 0 && (
                  <p className="text-sm text-gray-400 text-center py-2">No pending tasks</p>
                )}
              </div>
            </div>
          ) : (
            <button
              onClick={() => setShowTaskSelector(true)}
              className="w-full flex items-center justify-center gap-2 text-sm text-gray-500 hover:text-primary-500 transition-colors py-2"
            >
              <Link2 className="w-4 h-4" />
              {selectedTaskId && linkedTask
                ? `Linked: ${linkedTask.title.slice(0, 25)}${linkedTask.title.length > 25 ? '...' : ''}`
                : 'Link to a task'}
            </button>
          )}
        </div>
      )}

      {/* Controls */}
      <div className="flex justify-center gap-4 mb-8">
        {state === 'idle' || state === 'completed' ? (
          <button
            onClick={handleStart}
            className={cn(
              'kawaii-button flex items-center gap-2 text-lg px-8 py-3 bg-gradient-to-r',
              colors.gradient
            )}
          >
            <Play className="w-6 h-6" />
            Start
          </button>
        ) : state === 'running' ? (
          <>
            <button onClick={pause} className="kawaii-button flex items-center gap-2">
              <Pause className="w-5 h-5" />
              Pause
            </button>
            <button onClick={handleStop} className="kawaii-button-secondary flex items-center gap-2">
              <Square className="w-5 h-5" />
              Stop
            </button>
          </>
        ) : state === 'paused' ? (
          <>
            <button onClick={resume} className="kawaii-button flex items-center gap-2">
              <Play className="w-5 h-5" />
              Resume
            </button>
            <button onClick={handleStop} className="kawaii-button-secondary flex items-center gap-2">
              <Square className="w-5 h-5" />
              Stop
            </button>
          </>
        ) : null}
      </div>

      {/* Skip Button */}
      {(state === 'idle' || state === 'completed') && (
        <div className="text-center mb-8">
          <button
            onClick={phase === 'work' ? skipToBreak : skipToWork}
            className="text-sm text-gray-500 hover:text-primary-500 flex items-center gap-1 mx-auto transition-colors"
          >
            <SkipForward className="w-4 h-4" />
            Skip to {phase === 'work' ? 'break' : 'focus'}
          </button>
        </div>
      )}

      {/* Stats */}
      <div className="kawaii-card">
        <div className="grid grid-cols-3 gap-4 text-center">
          <div>
            <div className="text-3xl font-bold text-primary-600">{completedPomodoros}</div>
            <div className="text-sm text-gray-500">Pomodoros Today</div>
          </div>
          <div>
            <div className="text-3xl font-bold text-accent-600">
              {completedPomodoros * settings.workDuration}
            </div>
            <div className="text-sm text-gray-500">Minutes Focused</div>
          </div>
          <div>
            <div className="text-3xl font-bold text-green-600">
              {completedPomodoros * XP_REWARDS.pomodoro}
            </div>
            <div className="text-sm text-gray-500">XP Earned</div>
          </div>
        </div>
      </div>

      {/* Timer Settings Quick Access */}
      <div className="mt-6 text-center">
        <button
          onClick={() => setShowSettings(true)}
          className="text-sm text-gray-400 hover:text-gray-600 flex items-center gap-1 mx-auto transition-colors"
        >
          <Settings className="w-4 h-4" />
          Timer Settings ({settings.workDuration}/{settings.shortBreakDuration}/{settings.longBreakDuration})
        </button>
      </div>

      {/* Settings Modal */}
      <TimerSettingsModal
        isOpen={showSettings}
        onClose={() => setShowSettings(false)}
        settings={settings}
        onSave={updateSettings}
      />
    </div>
  );
}
