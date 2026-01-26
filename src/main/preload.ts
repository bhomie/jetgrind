import { contextBridge, ipcRenderer } from 'electron';
import { IPC_CHANNELS, type CreateTask, type UpdateTask, type TimerSettings } from '../shared/types';

const electronAPI = {
  // User
  getUser: () => ipcRenderer.invoke(IPC_CHANNELS.USER_GET),
  updateUser: (data: Partial<{ settings: Record<string, unknown> }>) =>
    ipcRenderer.invoke(IPC_CHANNELS.USER_UPDATE, data),
  addXp: (amount: number) => ipcRenderer.invoke(IPC_CHANNELS.USER_ADD_XP, amount),
  addCoins: (amount: number) => ipcRenderer.invoke(IPC_CHANNELS.USER_ADD_COINS, amount),

  // Tasks
  getAllTasks: () => ipcRenderer.invoke(IPC_CHANNELS.TASK_GET_ALL),
  getTask: (id: string) => ipcRenderer.invoke(IPC_CHANNELS.TASK_GET, id),
  createTask: (data: CreateTask) => ipcRenderer.invoke(IPC_CHANNELS.TASK_CREATE, data),
  updateTask: (id: string, data: UpdateTask) => ipcRenderer.invoke(IPC_CHANNELS.TASK_UPDATE, id, data),
  deleteTask: (id: string) => ipcRenderer.invoke(IPC_CHANNELS.TASK_DELETE, id),
  completeTask: (id: string) => ipcRenderer.invoke(IPC_CHANNELS.TASK_COMPLETE, id),

  // Timer
  getTimerSettings: () => ipcRenderer.invoke(IPC_CHANNELS.TIMER_GET_SETTINGS),
  updateTimerSettings: (settings: Partial<TimerSettings>) =>
    ipcRenderer.invoke(IPC_CHANNELS.TIMER_UPDATE_SETTINGS, settings),
  onTimerComplete: (session: {
    taskId: string | null;
    phase: string;
    duration: number;
    startedAt: Date;
    completedAt: Date;
    interrupted: boolean;
  }) => ipcRenderer.invoke(IPC_CHANNELS.TIMER_COMPLETE, session),

  // Pomodoro
  getTodayPomodoroCount: () => ipcRenderer.invoke(IPC_CHANNELS.POMODORO_GET_TODAY_COUNT),

  // Shop
  getShopItems: () => ipcRenderer.invoke(IPC_CHANNELS.SHOP_GET_ITEMS),
  purchaseItem: (itemId: string) => ipcRenderer.invoke(IPC_CHANNELS.SHOP_PURCHASE, itemId),

  // Inventory
  getInventory: () => ipcRenderer.invoke(IPC_CHANNELS.INVENTORY_GET),
  equipItem: (itemId: string) => ipcRenderer.invoke(IPC_CHANNELS.INVENTORY_EQUIP, itemId),
  unequipItem: (slot: string) => ipcRenderer.invoke(IPC_CHANNELS.INVENTORY_UNEQUIP, slot),

  // Window controls
  minimizeWindow: () => ipcRenderer.send(IPC_CHANNELS.WINDOW_MINIMIZE),
  maximizeWindow: () => ipcRenderer.send(IPC_CHANNELS.WINDOW_MAXIMIZE),
  closeWindow: () => ipcRenderer.send(IPC_CHANNELS.WINDOW_CLOSE),

  // Notifications
  showNotification: (title: string, body: string) =>
    ipcRenderer.invoke(IPC_CHANNELS.NOTIFICATION_SHOW, title, body),
};

contextBridge.exposeInMainWorld('electronAPI', electronAPI);

export type ElectronAPI = typeof electronAPI;
