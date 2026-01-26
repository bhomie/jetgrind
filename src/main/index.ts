import { app, BrowserWindow, ipcMain, Notification, shell } from 'electron';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { initDatabase, getUser, updateUser, addXp, addCoins } from './services/storage';

// ESM compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
import {
  getAllTasks,
  getTask,
  createTask,
  updateTask,
  deleteTask,
  completeTask,
} from './services/tasks';
import { getTimerSettings, updateTimerSettings } from './services/settings';
import {
  getShopItems,
  purchaseItem,
  getInventory,
  equipItem,
  unequipItem,
} from './services/shop';
import { getTodayPomodoroCount, savePomodoroSession } from './services/pomodoro';
import { IPC_CHANNELS } from '../shared/types';

let mainWindow: BrowserWindow | null = null;

const isDev = process.env.NODE_ENV === 'development' || !app.isPackaged;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    frame: false,
    titleBarStyle: 'hidden',
    backgroundColor: '#FEF1F7',
    webPreferences: {
      preload: join(__dirname, '../preload/preload.mjs'),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
    icon: join(__dirname, '../../assets/icons/icon.png'),
  });

  if (isDev) {
    mainWindow.loadURL('http://localhost:5173');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(join(__dirname, '../renderer/index.html'));
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Open external links in default browser
  mainWindow.webContents.setWindowOpenHandler(({ url }) => {
    shell.openExternal(url);
    return { action: 'deny' };
  });
}

function setupIpcHandlers() {
  // User handlers
  ipcMain.handle(IPC_CHANNELS.USER_GET, async () => {
    return await getUser();
  });

  ipcMain.handle(IPC_CHANNELS.USER_UPDATE, async (_event, data) => {
    return await updateUser(data);
  });

  ipcMain.handle(IPC_CHANNELS.USER_ADD_XP, async (_event, amount: number) => {
    return await addXp(amount);
  });

  ipcMain.handle(IPC_CHANNELS.USER_ADD_COINS, async (_event, amount: number) => {
    return await addCoins(amount);
  });

  // Task handlers
  ipcMain.handle(IPC_CHANNELS.TASK_GET_ALL, async () => {
    return await getAllTasks();
  });

  ipcMain.handle(IPC_CHANNELS.TASK_GET, async (_event, id: string) => {
    return await getTask(id);
  });

  ipcMain.handle(IPC_CHANNELS.TASK_CREATE, async (_event, data) => {
    return await createTask(data);
  });

  ipcMain.handle(IPC_CHANNELS.TASK_UPDATE, async (_event, id: string, data) => {
    return await updateTask(id, data);
  });

  ipcMain.handle(IPC_CHANNELS.TASK_DELETE, async (_event, id: string) => {
    return await deleteTask(id);
  });

  ipcMain.handle(IPC_CHANNELS.TASK_COMPLETE, async (_event, id: string) => {
    return await completeTask(id);
  });

  // Timer settings handlers
  ipcMain.handle(IPC_CHANNELS.TIMER_GET_SETTINGS, async () => {
    return await getTimerSettings();
  });

  ipcMain.handle(IPC_CHANNELS.TIMER_UPDATE_SETTINGS, async (_event, settings) => {
    return await updateTimerSettings(settings);
  });

  // Pomodoro handlers
  ipcMain.handle(IPC_CHANNELS.POMODORO_GET_TODAY_COUNT, async () => {
    return await getTodayPomodoroCount();
  });

  ipcMain.handle(IPC_CHANNELS.TIMER_COMPLETE, async (_event, session) => {
    return await savePomodoroSession(session);
  });

  // Shop handlers
  ipcMain.handle(IPC_CHANNELS.SHOP_GET_ITEMS, async () => {
    return await getShopItems();
  });

  ipcMain.handle(IPC_CHANNELS.SHOP_PURCHASE, async (_event, itemId: string) => {
    return await purchaseItem(itemId);
  });

  // Inventory handlers
  ipcMain.handle(IPC_CHANNELS.INVENTORY_GET, async () => {
    return await getInventory();
  });

  ipcMain.handle(IPC_CHANNELS.INVENTORY_EQUIP, async (_event, itemId: string) => {
    return await equipItem(itemId);
  });

  ipcMain.handle(IPC_CHANNELS.INVENTORY_UNEQUIP, async (_event, slot: string) => {
    return await unequipItem(slot);
  });

  // Window handlers
  ipcMain.on(IPC_CHANNELS.WINDOW_MINIMIZE, () => {
    mainWindow?.minimize();
  });

  ipcMain.on(IPC_CHANNELS.WINDOW_MAXIMIZE, () => {
    if (mainWindow?.isMaximized()) {
      mainWindow.unmaximize();
    } else {
      mainWindow?.maximize();
    }
  });

  ipcMain.on(IPC_CHANNELS.WINDOW_CLOSE, () => {
    mainWindow?.close();
  });

  // Notification handler
  ipcMain.handle(IPC_CHANNELS.NOTIFICATION_SHOW, async (_event, title: string, body: string) => {
    if (Notification.isSupported()) {
      new Notification({ title, body }).show();
    }
  });
}

app.whenReady().then(async () => {
  await initDatabase();
  setupIpcHandlers();
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
