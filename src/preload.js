// Ogulcan Erduran https://ogulcan.me

const { contextBridge, ipcRenderer } = require('electron');

contextBridge.exposeInMainWorld('winget', {
  checkUpdates: () => ipcRenderer.invoke('winget-check-updates'),
  listInstalled: () => ipcRenderer.invoke('winget-list'),
  search: (query) => ipcRenderer.invoke('winget-search', query),
  install: (id) => ipcRenderer.invoke('winget-install', id),
  upgradePackage: (id) => ipcRenderer.invoke('winget-upgrade-package', id),
  uninstall: (id) => ipcRenderer.invoke('winget-uninstall', id),
  exportPackages: (packages) => ipcRenderer.invoke('export-packages', packages),
  importPackages: () => ipcRenderer.invoke('import-packages')
});
