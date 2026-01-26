import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { useTimerStore } from '../renderer/stores/timerStore';

describe('Timer Store', () => {
  beforeEach(() => {
    vi.useFakeTimers();
    // Reset the store state
    useTimerStore.setState({
      state: 'idle',
      phase: 'work',
      timeRemaining: 25 * 60,
      totalTime: 25 * 60,
      completedPomodoros: 0,
      linkedTaskId: null,
      settings: {
        workDuration: 25,
        shortBreakDuration: 5,
        longBreakDuration: 15,
        longBreakInterval: 4,
        autoStartBreaks: false,
        autoStartPomodoros: false,
        soundEnabled: true,
        notificationsEnabled: true,
      },
      sessionStartedAt: null,
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.clearAllMocks();
  });

  describe('init', () => {
    it('should load settings and today count from API', async () => {
      const mockSettings = {
        workDuration: 30,
        shortBreakDuration: 10,
        longBreakDuration: 20,
        longBreakInterval: 3,
        autoStartBreaks: true,
        autoStartPomodoros: false,
        soundEnabled: false,
        notificationsEnabled: true,
      };

      window.electronAPI.getTimerSettings = vi.fn().mockResolvedValue(mockSettings);
      window.electronAPI.getTodayPomodoroCount = vi.fn().mockResolvedValue(5);

      const { init } = useTimerStore.getState();
      await init();

      const state = useTimerStore.getState();
      expect(state.settings).toEqual(mockSettings);
      expect(state.completedPomodoros).toBe(5);
      expect(state.timeRemaining).toBe(30 * 60);
    });
  });

  describe('start', () => {
    it('should start timer in running state', () => {
      const { start } = useTimerStore.getState();
      start();

      const state = useTimerStore.getState();
      expect(state.state).toBe('running');
      expect(state.sessionStartedAt).not.toBeNull();
    });

    it('should link task when provided', () => {
      const { start } = useTimerStore.getState();
      start('task-123');

      expect(useTimerStore.getState().linkedTaskId).toBe('task-123');
    });

    it('should set time based on current phase', () => {
      useTimerStore.setState({ phase: 'short_break' });

      const { start } = useTimerStore.getState();
      start();

      const state = useTimerStore.getState();
      expect(state.timeRemaining).toBe(5 * 60);
      expect(state.totalTime).toBe(5 * 60);
    });
  });

  describe('pause', () => {
    it('should pause running timer', () => {
      useTimerStore.setState({ state: 'running' });

      const { pause } = useTimerStore.getState();
      pause();

      expect(useTimerStore.getState().state).toBe('paused');
    });
  });

  describe('resume', () => {
    it('should resume paused timer', () => {
      useTimerStore.setState({ state: 'paused' });

      const { resume } = useTimerStore.getState();
      resume();

      expect(useTimerStore.getState().state).toBe('running');
    });
  });

  describe('stop', () => {
    it('should reset timer to idle state', () => {
      useTimerStore.setState({
        state: 'running',
        phase: 'short_break',
        timeRemaining: 120,
        linkedTaskId: 'task-123',
      });

      const { stop } = useTimerStore.getState();
      stop();

      const state = useTimerStore.getState();
      expect(state.state).toBe('idle');
      expect(state.phase).toBe('work');
      expect(state.timeRemaining).toBe(25 * 60);
      expect(state.linkedTaskId).toBeNull();
    });
  });

  describe('tick', () => {
    it('should decrement time when running', () => {
      useTimerStore.setState({ state: 'running', timeRemaining: 100 });

      const { tick } = useTimerStore.getState();
      tick();

      expect(useTimerStore.getState().timeRemaining).toBe(99);
    });

    it('should not decrement when not running', () => {
      useTimerStore.setState({ state: 'paused', timeRemaining: 100 });

      const { tick } = useTimerStore.getState();
      tick();

      expect(useTimerStore.getState().timeRemaining).toBe(100);
    });

    it('should transition to short break after work completion', () => {
      useTimerStore.setState({
        state: 'running',
        phase: 'work',
        timeRemaining: 1,
        completedPomodoros: 0,
        sessionStartedAt: new Date(),
      });

      window.electronAPI.onTimerComplete = vi.fn().mockResolvedValue({});
      window.electronAPI.showNotification = vi.fn();

      const { tick } = useTimerStore.getState();
      tick();

      const state = useTimerStore.getState();
      expect(state.phase).toBe('short_break');
      expect(state.completedPomodoros).toBe(1);
      expect(state.state).toBe('completed'); // autoStartBreaks is false
    });

    it('should transition to long break after interval', () => {
      useTimerStore.setState({
        state: 'running',
        phase: 'work',
        timeRemaining: 1,
        completedPomodoros: 3, // After this, it will be 4 (longBreakInterval)
        sessionStartedAt: new Date(),
      });

      window.electronAPI.onTimerComplete = vi.fn().mockResolvedValue({});
      window.electronAPI.showNotification = vi.fn();

      const { tick } = useTimerStore.getState();
      tick();

      const state = useTimerStore.getState();
      expect(state.phase).toBe('long_break');
      expect(state.completedPomodoros).toBe(4);
    });

    it('should transition to work after break completion', () => {
      useTimerStore.setState({
        state: 'running',
        phase: 'short_break',
        timeRemaining: 1,
        sessionStartedAt: new Date(),
      });

      window.electronAPI.onTimerComplete = vi.fn().mockResolvedValue({});
      window.electronAPI.showNotification = vi.fn();

      const { tick } = useTimerStore.getState();
      tick();

      expect(useTimerStore.getState().phase).toBe('work');
    });

    it('should auto-start break when enabled', () => {
      useTimerStore.setState({
        state: 'running',
        phase: 'work',
        timeRemaining: 1,
        completedPomodoros: 0,
        sessionStartedAt: new Date(),
        settings: {
          ...useTimerStore.getState().settings,
          autoStartBreaks: true,
        },
      });

      window.electronAPI.onTimerComplete = vi.fn().mockResolvedValue({});
      window.electronAPI.showNotification = vi.fn();

      const { tick } = useTimerStore.getState();
      tick();

      expect(useTimerStore.getState().state).toBe('running');
    });
  });

  describe('skipToBreak', () => {
    it('should skip to short break and increment pomodoros', () => {
      const { skipToBreak } = useTimerStore.getState();
      skipToBreak();

      const state = useTimerStore.getState();
      expect(state.phase).toBe('short_break');
      expect(state.completedPomodoros).toBe(1);
      expect(state.timeRemaining).toBe(5 * 60);
    });

    it('should skip to long break when at interval', () => {
      useTimerStore.setState({ completedPomodoros: 3 }); // After increment, will be 4

      const { skipToBreak } = useTimerStore.getState();
      skipToBreak();

      expect(useTimerStore.getState().phase).toBe('long_break');
      expect(useTimerStore.getState().timeRemaining).toBe(15 * 60);
    });
  });

  describe('skipToWork', () => {
    it('should skip to work phase', () => {
      useTimerStore.setState({ phase: 'short_break', timeRemaining: 120 });

      const { skipToWork } = useTimerStore.getState();
      skipToWork();

      const state = useTimerStore.getState();
      expect(state.phase).toBe('work');
      expect(state.timeRemaining).toBe(25 * 60);
    });
  });

  describe('updateSettings', () => {
    it('should update settings via API', async () => {
      const newSettings = {
        workDuration: 30,
        shortBreakDuration: 10,
        longBreakDuration: 20,
        longBreakInterval: 3,
        autoStartBreaks: true,
        autoStartPomodoros: true,
        soundEnabled: false,
        notificationsEnabled: false,
      };

      window.electronAPI.updateTimerSettings = vi.fn().mockResolvedValue(newSettings);

      const { updateSettings } = useTimerStore.getState();
      await updateSettings(newSettings);

      expect(window.electronAPI.updateTimerSettings).toHaveBeenCalledWith(newSettings);
      expect(useTimerStore.getState().settings).toEqual(newSettings);
    });

    it('should update time when idle', async () => {
      const newSettings = {
        ...useTimerStore.getState().settings,
        workDuration: 45,
      };

      window.electronAPI.updateTimerSettings = vi.fn().mockResolvedValue(newSettings);

      const { updateSettings } = useTimerStore.getState();
      await updateSettings(newSettings);

      expect(useTimerStore.getState().timeRemaining).toBe(45 * 60);
    });
  });
});
