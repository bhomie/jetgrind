import { create } from 'zustand';
import type { User } from '../../shared/types';
import { calculateXpProgress } from '../../shared/types';

interface UserState {
  user: User | null;
  loading: boolean;
  error: string | null;
  xpProgress: { current: number; required: number; percentage: number };

  init: () => Promise<void>;
  refresh: () => Promise<void>;
  addXp: (amount: number) => Promise<{ leveledUp: boolean; newLevel?: number }>;
  addCoins: (amount: number) => Promise<void>;
}

export const useUserStore = create<UserState>((set) => ({
  user: null,
  loading: true,
  error: null,
  xpProgress: { current: 0, required: 50, percentage: 0 },

  init: async () => {
    try {
      set({ loading: true, error: null });
      const user = await window.electronAPI.getUser();
      const xpProgress = calculateXpProgress(user?.xp || 0);
      set({ user, xpProgress, loading: false });
    } catch (err) {
      set({ error: 'Failed to load user', loading: false });
    }
  },

  refresh: async () => {
    try {
      const user = await window.electronAPI.getUser();
      const xpProgress = calculateXpProgress(user?.xp || 0);
      set({ user, xpProgress });
    } catch (err) {
      console.error('Failed to refresh user:', err);
    }
  },

  addXp: async (amount: number) => {
    try {
      const result = await window.electronAPI.addXp(amount);
      const { user } = result;
      const xpProgress = calculateXpProgress(user?.xp || 0);
      set({ user, xpProgress });
      return { leveledUp: result.leveledUp, newLevel: result.newLevel };
    } catch (err) {
      console.error('Failed to add XP:', err);
      return { leveledUp: false };
    }
  },

  addCoins: async (amount: number) => {
    try {
      const user = await window.electronAPI.addCoins(amount);
      set({ user });
    } catch (err) {
      console.error('Failed to add coins:', err);
    }
  },
}));
