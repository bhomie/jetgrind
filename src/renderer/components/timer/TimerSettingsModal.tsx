import { useState, useEffect } from 'react';
import { X, Clock, Coffee, Moon, Bell, Volume2, Play } from 'lucide-react';
import type { TimerSettings } from '../../../shared/types';
import { cn } from '../../utils/cn';
import { playTimerComplete } from '../../utils/sounds';

interface TimerSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
  settings: TimerSettings;
  onSave: (settings: Partial<TimerSettings>) => Promise<void>;
}

export function TimerSettingsModal({ isOpen, onClose, settings, onSave }: TimerSettingsModalProps) {
  const [workDuration, setWorkDuration] = useState(settings.workDuration);
  const [shortBreakDuration, setShortBreakDuration] = useState(settings.shortBreakDuration);
  const [longBreakDuration, setLongBreakDuration] = useState(settings.longBreakDuration);
  const [longBreakInterval, setLongBreakInterval] = useState(settings.longBreakInterval);
  const [autoStartBreaks, setAutoStartBreaks] = useState(settings.autoStartBreaks);
  const [autoStartPomodoros, setAutoStartPomodoros] = useState(settings.autoStartPomodoros);
  const [soundEnabled, setSoundEnabled] = useState(settings.soundEnabled);
  const [notificationsEnabled, setNotificationsEnabled] = useState(settings.notificationsEnabled);
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    setWorkDuration(settings.workDuration);
    setShortBreakDuration(settings.shortBreakDuration);
    setLongBreakDuration(settings.longBreakDuration);
    setLongBreakInterval(settings.longBreakInterval);
    setAutoStartBreaks(settings.autoStartBreaks);
    setAutoStartPomodoros(settings.autoStartPomodoros);
    setSoundEnabled(settings.soundEnabled);
    setNotificationsEnabled(settings.notificationsEnabled);
  }, [settings, isOpen]);

  const handleSave = async () => {
    setSaving(true);
    try {
      await onSave({
        workDuration,
        shortBreakDuration,
        longBreakDuration,
        longBreakInterval,
        autoStartBreaks,
        autoStartPomodoros,
        soundEnabled,
        notificationsEnabled,
      });
      onClose();
    } finally {
      setSaving(false);
    }
  };

  const handleTestSound = () => {
    playTimerComplete();
  };

  if (!isOpen) return null;

  const presets = [
    { label: 'Classic', work: 25, short: 5, long: 15 },
    { label: 'Short', work: 15, short: 3, long: 10 },
    { label: 'Long Focus', work: 50, short: 10, long: 30 },
    { label: 'ADHD Friendly', work: 10, short: 2, long: 5 },
  ];

  const applyPreset = (preset: { work: number; short: number; long: number }) => {
    setWorkDuration(preset.work);
    setShortBreakDuration(preset.short);
    setLongBreakDuration(preset.long);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center">
      {/* Backdrop */}
      <div className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={onClose} />

      {/* Modal */}
      <div className="relative bg-white rounded-3xl shadow-2xl w-full max-w-lg mx-4 animate-scale-up max-h-[90vh] overflow-y-auto">
        {/* Header */}
        <div className="sticky top-0 bg-white flex items-center justify-between p-6 border-b border-gray-100 rounded-t-3xl">
          <h2 className="text-xl font-bold text-gray-800">Timer Settings</h2>
          <button
            onClick={onClose}
            className="p-2 text-gray-400 hover:text-gray-600 hover:bg-gray-100 rounded-xl transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6 space-y-6">
          {/* Presets */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-3">Quick Presets</label>
            <div className="flex flex-wrap gap-2">
              {presets.map((preset) => (
                <button
                  key={preset.label}
                  onClick={() => applyPreset(preset)}
                  className={cn(
                    'px-3 py-1.5 rounded-full text-sm font-medium transition-all border-2',
                    workDuration === preset.work &&
                      shortBreakDuration === preset.short &&
                      longBreakDuration === preset.long
                      ? 'bg-primary-100 border-primary-300 text-primary-700'
                      : 'bg-gray-50 border-gray-200 text-gray-600 hover:border-gray-300'
                  )}
                >
                  {preset.label}
                </button>
              ))}
            </div>
          </div>

          {/* Duration Settings */}
          <div className="space-y-4">
            <h3 className="text-sm font-medium text-gray-700">Duration (minutes)</h3>

            {/* Work Duration */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 w-36">
                <Clock className="w-5 h-5 text-primary-500" />
                <span className="text-sm text-gray-600">Focus</span>
              </div>
              <input
                type="range"
                min="5"
                max="60"
                value={workDuration}
                onChange={(e) => setWorkDuration(Number(e.target.value))}
                className="flex-1 h-2 bg-primary-100 rounded-full appearance-none cursor-pointer accent-primary-500"
              />
              <span className="w-12 text-right font-medium text-gray-800">{workDuration}</span>
            </div>

            {/* Short Break Duration */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 w-36">
                <Coffee className="w-5 h-5 text-green-500" />
                <span className="text-sm text-gray-600">Short Break</span>
              </div>
              <input
                type="range"
                min="1"
                max="30"
                value={shortBreakDuration}
                onChange={(e) => setShortBreakDuration(Number(e.target.value))}
                className="flex-1 h-2 bg-green-100 rounded-full appearance-none cursor-pointer accent-green-500"
              />
              <span className="w-12 text-right font-medium text-gray-800">{shortBreakDuration}</span>
            </div>

            {/* Long Break Duration */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 w-36">
                <Moon className="w-5 h-5 text-blue-500" />
                <span className="text-sm text-gray-600">Long Break</span>
              </div>
              <input
                type="range"
                min="5"
                max="60"
                value={longBreakDuration}
                onChange={(e) => setLongBreakDuration(Number(e.target.value))}
                className="flex-1 h-2 bg-blue-100 rounded-full appearance-none cursor-pointer accent-blue-500"
              />
              <span className="w-12 text-right font-medium text-gray-800">{longBreakDuration}</span>
            </div>

            {/* Long Break Interval */}
            <div className="flex items-center gap-4">
              <div className="flex items-center gap-2 w-36">
                <span className="text-sm text-gray-600">Long break after</span>
              </div>
              <div className="flex items-center gap-2">
                <button
                  onClick={() => setLongBreakInterval(Math.max(2, longBreakInterval - 1))}
                  className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-600 font-medium transition-colors"
                >
                  -
                </button>
                <span className="w-8 text-center font-medium text-gray-800">{longBreakInterval}</span>
                <button
                  onClick={() => setLongBreakInterval(Math.min(8, longBreakInterval + 1))}
                  className="w-8 h-8 rounded-full bg-gray-100 hover:bg-gray-200 text-gray-600 font-medium transition-colors"
                >
                  +
                </button>
                <span className="text-sm text-gray-500">pomodoros</span>
              </div>
            </div>
          </div>

          {/* Auto-start Settings */}
          <div className="space-y-3">
            <h3 className="text-sm font-medium text-gray-700">Auto-start</h3>

            <label className="flex items-center justify-between p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <Play className="w-5 h-5 text-green-500" />
                <span className="text-sm text-gray-700">Auto-start breaks</span>
              </div>
              <input
                type="checkbox"
                checked={autoStartBreaks}
                onChange={(e) => setAutoStartBreaks(e.target.checked)}
                className="w-5 h-5 rounded accent-primary-500"
              />
            </label>

            <label className="flex items-center justify-between p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <Clock className="w-5 h-5 text-primary-500" />
                <span className="text-sm text-gray-700">Auto-start pomodoros</span>
              </div>
              <input
                type="checkbox"
                checked={autoStartPomodoros}
                onChange={(e) => setAutoStartPomodoros(e.target.checked)}
                className="w-5 h-5 rounded accent-primary-500"
              />
            </label>
          </div>

          {/* Notification Settings */}
          <div className="space-y-3">
            <h3 className="text-sm font-medium text-gray-700">Notifications</h3>

            <label className="flex items-center justify-between p-3 bg-gray-50 rounded-xl cursor-pointer hover:bg-gray-100 transition-colors">
              <div className="flex items-center gap-3">
                <Bell className="w-5 h-5 text-accent-500" />
                <span className="text-sm text-gray-700">Desktop notifications</span>
              </div>
              <input
                type="checkbox"
                checked={notificationsEnabled}
                onChange={(e) => setNotificationsEnabled(e.target.checked)}
                className="w-5 h-5 rounded accent-primary-500"
              />
            </label>

            <div className="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
              <label className="flex items-center gap-3 cursor-pointer flex-1">
                <Volume2 className="w-5 h-5 text-accent-500" />
                <span className="text-sm text-gray-700">Sound effects</span>
              </label>
              <div className="flex items-center gap-2">
                <button
                  onClick={handleTestSound}
                  className="px-2 py-1 text-xs text-primary-600 hover:bg-primary-100 rounded transition-colors"
                >
                  Test
                </button>
                <input
                  type="checkbox"
                  checked={soundEnabled}
                  onChange={(e) => setSoundEnabled(e.target.checked)}
                  className="w-5 h-5 rounded accent-primary-500"
                />
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="sticky bottom-0 bg-white flex justify-end gap-3 p-6 border-t border-gray-100 rounded-b-3xl">
          <button onClick={onClose} className="kawaii-button-secondary">
            Cancel
          </button>
          <button
            onClick={handleSave}
            disabled={saving}
            className="kawaii-button disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? 'Saving...' : 'Save Settings'}
          </button>
        </div>
      </div>
    </div>
  );
}
