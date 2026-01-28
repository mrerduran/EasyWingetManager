// Ogulcan Erduran https://ogulcan.me

const { app, BrowserWindow, ipcMain, dialog } = require('electron');
const path = require('path');
const { execFile } = require('child_process');
const fs = require('fs');
const crypto = require('crypto');

// Encryption constants
const ENCRYPTION_KEY = crypto.scryptSync('easy-winget-manager-secret', 'salt', 32);
const IV_LENGTH = 16;

function encrypt(text) {
  const iv = crypto.randomBytes(IV_LENGTH);
  const cipher = crypto.createCipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let encrypted = cipher.update(text);
  encrypted = Buffer.concat([encrypted, cipher.final()]);
  return iv.toString('hex') + ':' + encrypted.toString('hex');
}

function decrypt(text) {
  const textParts = text.split(':');
  const iv = Buffer.from(textParts.shift(), 'hex');
  const encryptedText = Buffer.from(textParts.join(':'), 'hex');
  const decipher = crypto.createDecipheriv('aes-256-cbc', ENCRYPTION_KEY, iv);
  let decrypted = decipher.update(encryptedText);
  decrypted = Buffer.concat([decrypted, decipher.final()]);
  return decrypted.toString();
}

// Function to create the main window
function createWindow() {
  const mainWindow = new BrowserWindow({
    width: 1000,
    height: 700,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    },
    autoHideMenuBar: true
  });

  mainWindow.loadFile(path.join(__dirname, 'index.html'));
  
  // Open DevTools in development mode (optional)
  // mainWindow.webContents.openDevTools();
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', function () {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});

app.on('window-all-closed', function () {
  if (process.platform !== 'darwin') app.quit();
});

// Helper function to execute commands
const runCommand = (file, args) => {
  return new Promise((resolve) => {
    // Increase maxBuffer to handle large outputs (e.g. winget list)
    // Use execFile to avoid spawning a shell and preventing command injection
    execFile(file, args, { maxBuffer: 1024 * 1024 * 5, encoding: 'utf8' }, (error, stdout, stderr) => {
      if (error) {
        console.error(`Command error: ${error.message}`);
      }
      resolve({ stdout, stderr, error });
    });
  });
};

// IPC Handlers

// 1. Check for updates
ipcMain.handle('winget-check-updates', async () => {
  // 'winget upgrade' lists available updates
  // Enforcing source 'winget' and removing unknown versions as requested
  return await runCommand('winget', ['upgrade', '--source', 'winget']);
});

// 2. List installed packages
ipcMain.handle('winget-list', async () => {
  // Only list packages from 'winget' source
  return await runCommand('winget', ['list', '--source', 'winget']);
});

// 3. Search packages
ipcMain.handle('winget-search', async (event, query) => {
  if (!query) return { stdout: '', stderr: 'No query provided', error: null };
  // Only search in 'winget' source
  return await runCommand('winget', ['search', query, '--source', 'winget']);
});

// 4. Install package
ipcMain.handle('winget-install', async (event, packageId) => {
  if (!packageId) return { stdout: '', stderr: 'No ID provided', error: null };
  // --accept-package-agreements --accept-source-agreements to avoid prompts blocking
  // Also enforce source winget for installation to be safe
  return await runCommand('winget', ['install', '--id', packageId, '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements']);
});

// 5. Upgrade specific package
ipcMain.handle('winget-upgrade-package', async (event, packageId) => {
  if (!packageId) return { stdout: '', stderr: 'No ID provided', error: null };
  // Enforce source winget
  return await runCommand('winget', ['upgrade', '--id', packageId, '--source', 'winget', '--accept-package-agreements', '--accept-source-agreements']);
});

// 6. Uninstall package
ipcMain.handle('winget-uninstall', async (event, packageId) => {
    if (!packageId) return { stdout: '', stderr: 'No ID provided', error: null };
    return await runCommand('winget', ['uninstall', '--id', packageId]);
  });

// 7. Export Packages
ipcMain.handle('export-packages', async (event, packages) => {
  if (!packages || packages.length === 0) {
    return { success: false, message: 'No packages to export.' };
  }

  const { filePath } = await dialog.showSaveDialog({
    title: 'Export Packages',
    defaultPath: 'mypackages.ogulcanerduran',
    filters: [{ name: 'Encrypted Winget Packages', extensions: ['ogulcanerduran'] }]
  });

  if (!filePath) {
    return { success: false, message: 'Export cancelled.' };
  }

  try {
    const data = JSON.stringify(packages);
    const encryptedData = encrypt(data);
    fs.writeFileSync(filePath, encryptedData, 'utf8');
    return { success: true, message: `Successfully exported ${packages.length} packages to ${path.basename(filePath)}` };
  } catch (error) {
    return { success: false, message: `Export failed: ${error.message}` };
  }
});

// 8. Import Packages
ipcMain.handle('import-packages', async () => {
  const { filePaths } = await dialog.showOpenDialog({
    title: 'Import Packages',
    filters: [{ name: 'Encrypted Winget Packages', extensions: ['ogulcanerduran'] }],
    properties: ['openFile']
  });

  if (!filePaths || filePaths.length === 0) {
    return { success: false, message: 'Import cancelled.' };
  }

  try {
    const encryptedData = fs.readFileSync(filePaths[0], 'utf8');
    const decryptedData = decrypt(encryptedData);
    const packages = JSON.parse(decryptedData);
    return { success: true, packages, message: `Successfully imported ${packages.length} packages.` };
  } catch (error) {
    console.error(error);
    return { success: false, message: `Import failed: Invalid file or corruption. (${error.message})` };
  }
});
