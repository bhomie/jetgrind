const { app, BrowserWindow, Menu, Tray, nativeImage } = require('electron');
const path = require('path');
const Store = require('electron-store');

const store = new Store();

let mainWindow;
let tray;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1200,
    height: 800,
    minWidth: 800,
    minHeight: 600,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false,
    },
    titleBarStyle: 'hiddenInset', // macOS native title bar
    backgroundColor: '#ffffff',
  });

  // Load the app
  if (process.env.NODE_ENV === 'development') {
    mainWindow.loadURL('http://localhost:3000');
    mainWindow.webContents.openDevTools();
  } else {
    mainWindow.loadFile(path.join(__dirname, 'build', 'index.html'));
  }

  // Create tray icon
  const icon = nativeImage.createFromPath(path.join(__dirname, 'assets', 'icon.png'));
  tray = new Tray(icon);
  
  const contextMenu = Menu.buildFromTemplate([
    { label: 'Show App', click: () => mainWindow.show() },
    { label: 'Start Pomodoro', click: () => mainWindow.webContents.send('start-pomodoro') },
    { type: 'separator' },
    { label: 'Quit', click: () => app.quit() }
  ]);
  
  tray.setToolTip('JetSet');
  tray.setContextMenu(contextMenu);

  // Handle window close
  mainWindow.on('close', (event) => {
    if (!app.isQuitting) {
      event.preventDefault();
      mainWindow.hide();
    }
    return false;
  });
}

// Create menu template
const template = [
  {
    label: 'File',
    submenu: [
      { label: 'New Task', accelerator: 'CmdOrCtrl+N', click: () => mainWindow.webContents.send('new-task') },
      { type: 'separator' },
      { role: 'quit' }
    ]
  },
  {
    label: 'View',
    submenu: [
      { role: 'reload' },
      { role: 'forceReload' },
      { role: 'toggleDevTools' },
      { type: 'separator' },
      { role: 'resetZoom' },
      { role: 'zoomIn' },
      { role: 'zoomOut' },
      { type: 'separator' },
      { role: 'togglefullscreen' }
    ]
  },
  {
    label: 'Pomodoro',
    submenu: [
      { label: 'Start', accelerator: 'CmdOrCtrl+P', click: () => mainWindow.webContents.send('start-pomodoro') },
      { label: 'Pause', accelerator: 'CmdOrCtrl+Shift+P', click: () => mainWindow.webContents.send('pause-pomodoro') },
      { label: 'Reset', accelerator: 'CmdOrCtrl+R', click: () => mainWindow.webContents.send('reset-pomodoro') }
    ]
  }
];

app.whenReady().then(() => {
  createWindow();
  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);

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

app.on('before-quit', () => {
  app.isQuitting = true;
}); 