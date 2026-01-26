import { create } from 'zustand';

export type ToastType = 'success' | 'error' | 'info' | 'reward';

export interface Toast {
  id: string;
  type: ToastType;
  title: string;
  message?: string;
  xp?: number;
  coins?: number;
  duration?: number;
}

interface ToastState {
  toasts: Toast[];
  addToast: (toast: Omit<Toast, 'id'>) => void;
  removeToast: (id: string) => void;
  showReward: (xp: number, coins: number, title?: string) => void;
  showSuccess: (title: string, message?: string) => void;
  showError: (title: string, message?: string) => void;
  showLevelUp: (newLevel: number) => void;
}

let toastId = 0;

export const useToastStore = create<ToastState>((set, get) => ({
  toasts: [],

  addToast: (toast) => {
    const id = `toast-${++toastId}`;
    const duration = toast.duration ?? 3000;

    set((state) => ({
      toasts: [...state.toasts, { ...toast, id }],
    }));

    // Auto-remove after duration
    setTimeout(() => {
      get().removeToast(id);
    }, duration);
  },

  removeToast: (id) => {
    set((state) => ({
      toasts: state.toasts.filter((t) => t.id !== id),
    }));
  },

  showReward: (xp, coins, title = 'Reward Earned!') => {
    get().addToast({
      type: 'reward',
      title,
      xp,
      coins,
      duration: 4000,
    });
  },

  showSuccess: (title, message) => {
    get().addToast({
      type: 'success',
      title,
      message,
    });
  },

  showError: (title, message) => {
    get().addToast({
      type: 'error',
      title,
      message,
      duration: 5000,
    });
  },

  showLevelUp: (newLevel) => {
    get().addToast({
      type: 'reward',
      title: '🎉 Level Up!',
      message: `You reached level ${newLevel}!`,
      duration: 5000,
    });
  },
}));
