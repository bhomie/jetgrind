import '@testing-library/jest-dom';
import { vi } from 'vitest';

// Mock electron API
const mockElectronAPI = {
  getUser: vi.fn().mockResolvedValue({
    id: '1',
    xp: 0,
    level: 1,
    coins: 100,
    streak: 0,
    lastActiveDate: null,
    settings: '{}',
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  updateUser: vi.fn().mockResolvedValue({}),
  addXp: vi.fn().mockResolvedValue({ user: { xp: 25, level: 1 }, leveledUp: false }),
  addCoins: vi.fn().mockResolvedValue({ coins: 125 }),

  getAllTasks: vi.fn().mockResolvedValue([]),
  getTask: vi.fn().mockResolvedValue(null),
  createTask: vi.fn().mockResolvedValue({
    id: 'test-task-1',
    title: 'Test Task',
    status: 'pending',
    priority: 'medium',
    size: 'medium',
    xpReward: 25,
    coinReward: 15,
    parentId: null,
    dueDate: null,
    completedAt: null,
    createdAt: new Date(),
    updatedAt: new Date(),
  }),
  updateTask: vi.fn().mockResolvedValue({}),
  deleteTask: vi.fn().mockResolvedValue({}),
  completeTask: vi.fn().mockResolvedValue({ xpEarned: 25, coinsEarned: 15, leveledUp: false }),

  getTimerSettings: vi.fn().mockResolvedValue({
    workDuration: 25,
    shortBreakDuration: 5,
    longBreakDuration: 15,
    longBreakInterval: 4,
    autoStartBreaks: false,
    autoStartPomodoros: false,
    soundEnabled: true,
    notificationsEnabled: true,
  }),
  updateTimerSettings: vi.fn().mockResolvedValue({}),
  onTimerComplete: vi.fn().mockResolvedValue({}),
  getTodayPomodoroCount: vi.fn().mockResolvedValue(0),

  getShopItems: vi.fn().mockResolvedValue([]),
  purchaseItem: vi.fn().mockResolvedValue({ success: true }),
  getInventory: vi.fn().mockResolvedValue([]),
  equipItem: vi.fn().mockResolvedValue({ success: true }),
  unequipItem: vi.fn().mockResolvedValue({ success: true }),

  minimizeWindow: vi.fn(),
  maximizeWindow: vi.fn(),
  closeWindow: vi.fn(),
  showNotification: vi.fn().mockResolvedValue(undefined),
};

// Stub the electronAPI on window
Object.defineProperty(window, 'electronAPI', {
  value: mockElectronAPI,
  writable: true,

});

// Reset mocks between tests
export function resetMocks() {
  Object.values(mockElectronAPI).forEach((mock) => {
    if (typeof mock === 'function' && mock.mockReset) {
      mock.mockReset();
    }
  });
}
