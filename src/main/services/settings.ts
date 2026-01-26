import Store from 'electron-store';
import { type TimerSettings, TimerSettingsSchema } from '../../shared/types';

const store = new Store<{ timerSettings: TimerSettings }>({
  defaults: {
    timerSettings: {
      workDuration: 25,
      shortBreakDuration: 5,
      longBreakDuration: 15,
      longBreakInterval: 4,
      autoStartBreaks: false,
      autoStartPomodoros: false,
      soundEnabled: true,
      notificationsEnabled: true,
    },
  },
});

export async function getTimerSettings(): Promise<TimerSettings> {
  const settings = store.get('timerSettings');
  return TimerSettingsSchema.parse(settings);
}

export async function updateTimerSettings(settings: Partial<TimerSettings>): Promise<TimerSettings> {
  const current = store.get('timerSettings');
  const updated = { ...current, ...settings };
  const validated = TimerSettingsSchema.parse(updated);
  store.set('timerSettings', validated);
  return validated;
}
