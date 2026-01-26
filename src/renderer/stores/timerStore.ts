import { create } from 'zustand';
import type { TimerState, PomodoroPhase, TimerSettings } from '../../shared/types';

interface TimerStoreState {
  state: TimerState;
  phase: PomodoroPhase;
  timeRemaining: number;
  totalTime: number;
  completedPomodoros: number;
  linkedTaskId: string | null;
  settings: TimerSettings;
  sessionStartedAt: Date | null;

  init: () => Promise<void>;
  start: (taskId?: string) => void;
  pause: () => void;
  resume: () => void;
  stop: () => void;
  tick: () => void;
  skipToBreak: () => void;
  skipToWork: () => void;
  updateSettings: (settings: Partial<TimerSettings>) => Promise<void>;
}

const DEFAULT_SETTINGS: TimerSettings = {
  workDuration: 25,
  shortBreakDuration: 5,
  longBreakDuration: 15,
  longBreakInterval: 4,
  autoStartBreaks: false,
  autoStartPomodoros: false,
  soundEnabled: true,
  notificationsEnabled: true,
};

let timerInterval: ReturnType<typeof setInterval> | null = null;

export const useTimerStore = create<TimerStoreState>((set, get) => ({
  state: 'idle',
  phase: 'work',
  timeRemaining: 25 * 60,
  totalTime: 25 * 60,
  completedPomodoros: 0,
  linkedTaskId: null,
  settings: DEFAULT_SETTINGS,
  sessionStartedAt: null,

  init: async () => {
    try {
      const settings = await window.electronAPI.getTimerSettings();
      const todayCount = await window.electronAPI.getTodayPomodoroCount();
      const timeRemaining = settings.workDuration * 60;
      set({
        settings,
        timeRemaining,
        totalTime: timeRemaining,
        completedPomodoros: todayCount,
      });
    } catch (err) {
      console.error('Failed to init timer:', err);
    }
  },

  start: (taskId?: string) => {
    const { settings, phase } = get();
    const duration = phase === 'work'
      ? settings.workDuration
      : phase === 'short_break'
        ? settings.shortBreakDuration
        : settings.longBreakDuration;

    set({
      state: 'running',
      timeRemaining: duration * 60,
      totalTime: duration * 60,
      linkedTaskId: taskId || null,
      sessionStartedAt: new Date(),
    });

    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => get().tick(), 1000);
  },

  pause: () => {
    set({ state: 'paused' });
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = null;
    }
  },

  resume: () => {
    set({ state: 'running' });
    if (timerInterval) clearInterval(timerInterval);
    timerInterval = setInterval(() => get().tick(), 1000);
  },

  stop: () => {
    const { phase, linkedTaskId, totalTime, timeRemaining, sessionStartedAt } = get();

    // Save interrupted session
    if (sessionStartedAt && phase === 'work') {
      window.electronAPI.onTimerComplete({
        taskId: linkedTaskId,
        phase,
        duration: totalTime - timeRemaining,
        startedAt: sessionStartedAt,
        completedAt: new Date(),
        interrupted: true,
      });
    }

    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = null;
    }

    const { settings } = get();
    set({
      state: 'idle',
      phase: 'work',
      timeRemaining: settings.workDuration * 60,
      totalTime: settings.workDuration * 60,
      linkedTaskId: null,
      sessionStartedAt: null,
    });
  },

  tick: () => {
    const { timeRemaining, state, phase, settings, completedPomodoros, linkedTaskId, totalTime, sessionStartedAt } = get();

    if (state !== 'running') return;

    if (timeRemaining <= 1) {
      // Timer completed
      if (timerInterval) {
        clearInterval(timerInterval);
        timerInterval = null;
      }

      // Save completed session
      if (sessionStartedAt) {
        window.electronAPI.onTimerComplete({
          taskId: linkedTaskId,
          phase,
          duration: totalTime,
          startedAt: sessionStartedAt,
          completedAt: new Date(),
          interrupted: false,
        });
      }

      // Show notification
      if (settings.notificationsEnabled) {
        const title = phase === 'work' ? 'Pomodoro Complete!' : 'Break Over!';
        const body = phase === 'work'
          ? 'Great job! Take a break.'
          : 'Ready to focus again?';
        window.electronAPI.showNotification(title, body);
      }

      // Determine next phase
      let nextPhase: PomodoroPhase;
      let newCompletedPomodoros = completedPomodoros;

      if (phase === 'work') {
        newCompletedPomodoros = completedPomodoros + 1;
        nextPhase = newCompletedPomodoros % settings.longBreakInterval === 0
          ? 'long_break'
          : 'short_break';
      } else {
        nextPhase = 'work';
      }

      const nextDuration = nextPhase === 'work'
        ? settings.workDuration
        : nextPhase === 'short_break'
          ? settings.shortBreakDuration
          : settings.longBreakDuration;

      const shouldAutoStart = nextPhase === 'work'
        ? settings.autoStartPomodoros
        : settings.autoStartBreaks;

      set({
        state: shouldAutoStart ? 'running' : 'completed',
        phase: nextPhase,
        timeRemaining: nextDuration * 60,
        totalTime: nextDuration * 60,
        completedPomodoros: newCompletedPomodoros,
        sessionStartedAt: shouldAutoStart ? new Date() : null,
      });

      if (shouldAutoStart) {
        timerInterval = setInterval(() => get().tick(), 1000);
      }
    } else {
      set({ timeRemaining: timeRemaining - 1 });
    }
  },

  skipToBreak: () => {
    const { settings, completedPomodoros } = get();
    const nextPhase = (completedPomodoros + 1) % settings.longBreakInterval === 0
      ? 'long_break'
      : 'short_break';
    const duration = nextPhase === 'short_break'
      ? settings.shortBreakDuration
      : settings.longBreakDuration;

    set({
      state: 'idle',
      phase: nextPhase,
      timeRemaining: duration * 60,
      totalTime: duration * 60,
      completedPomodoros: completedPomodoros + 1,
    });
  },

  skipToWork: () => {
    const { settings } = get();
    set({
      state: 'idle',
      phase: 'work',
      timeRemaining: settings.workDuration * 60,
      totalTime: settings.workDuration * 60,
    });
  },

  updateSettings: async (newSettings: Partial<TimerSettings>) => {
    try {
      const updated = await window.electronAPI.updateTimerSettings(newSettings);
      set({ settings: updated });

      // Update time if idle
      const { state, phase } = get();
      if (state === 'idle') {
        const duration = phase === 'work'
          ? updated.workDuration
          : phase === 'short_break'
            ? updated.shortBreakDuration
            : updated.longBreakDuration;
        set({
          timeRemaining: duration * 60,
          totalTime: duration * 60,
        });
      }
    } catch (err) {
      console.error('Failed to update settings:', err);
    }
  },
}));
