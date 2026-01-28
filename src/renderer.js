// Ogulcan Erduran https://ogulcan.me

// State
let currentSection = 'updates';

// DOM Elements
const navItems = {
    updates: document.getElementById('nav-updates'),
    installed: document.getElementById('nav-installed'),
    search: document.getElementById('nav-search'),
    backup: document.getElementById('nav-backup')
};

// Add keyboard navigation support
Object.values(navItems).forEach(item => {
    item.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            item.click();
        }
    });
});

const sections = {
    updates: document.getElementById('section-updates'),
    installed: document.getElementById('section-installed'),
    search: document.getElementById('section-search'),
    backup: document.getElementById('section-backup')
};

const containers = {
    updates: document.getElementById('updates-container'),
    installed: document.getElementById('installed-container'),
    search: document.getElementById('search-results'),
    importList: document.getElementById('import-list-container'),
    exportList: document.getElementById('export-list-container')
};

const loadingOverlay = document.getElementById('loading-overlay');
const loadingMessage = document.getElementById('loading-message');

// Navigation
function showSection(sectionName) {
    // Update Nav
    Object.values(navItems).forEach(el => el.classList.remove('active'));
    navItems[sectionName].classList.add('active');

    // Update Section
    Object.values(sections).forEach(el => el.classList.remove('active-section'));
    sections[sectionName].classList.add('active-section');

    currentSection = sectionName;

    // Auto-load data based on section
    if (sectionName === 'updates') {
        // Trigger check updates logic
        document.getElementById('btn-check-updates').click();
    } else if (sectionName === 'installed') {
        // Trigger load installed logic
        loadInstalledPackages();
    } else if (sectionName === 'search') {
        // Clear search results or focus input
        document.getElementById('search-input').focus();
    }
}

// Helper: Check if package is valid
function isValidPackage(pkg) {
    // 1. Source check (if available in output, though we enforce it in backend)
    // Sometimes source is empty string in list output even if from winget, 
    // but usually 'winget' source packages have 'winget' in the source column.
    // However, the user wants "only winget" source.
    if (pkg.source && pkg.source.toLowerCase() !== 'winget') {
        // If source is explicit and NOT winget, skip.
        // But be careful: winget list output sometimes has empty source column for locally installed apps?
        // If backend enforces --source winget, then we can trust the source is winget-compatible.
    }

    // 2. Version check: "Unknown" versions should be filtered out
    if (!pkg.version || pkg.version.toLowerCase() === 'unknown') {
        return false;
    }

    // 3. ID check: "Verified publisher" / "Publisher.Package" format
    // Should contain at least one dot.
    // Should NOT be a random string (like MS Store IDs which are often just alphanumeric without dots, e.g. 9NBLGGH4NNS1)
    if (!pkg.id.includes('.')) {
        return false;
    }
    
    // Additional heuristic: ensure ID isn't just a simple name (though "7zip.7zip" is valid)
    // The main criteria user gave: "package IDs should be like Microsoft.VisualStudioCode"
    // and "not random number ID packages".
    
    return true;
}

// Helper: Parse Winget Output
function parseWingetOutput(stdout) {
    const lines = stdout.split('\n');
    const packages = [];
    let startParsing = false;

    for (const line of lines) {
        if (line.trim().length === 0) continue;
        
        // Winget output usually has a separator line starting with ---
        if (line.startsWith('---')) {
            startParsing = true;
            continue;
        }

        if (startParsing) {
            // Split by 2 or more spaces
            const parts = line.trim().split(/\s{2,}/);
            
            // Basic heuristic: Name, Id, Version, [Available], [Source]
            if (parts.length >= 2) {
                const pkg = {
                    name: parts[0],
                    id: parts[1],
                    version: parts[2] || 'Unknown',
                    available: parts[3] || '',
                    source: parts.length > 4 ? parts[4] : (parts.length === 4 ? parts[3] : '') 
                };

                if (isValidPackage(pkg)) {
                    packages.push(pkg);
                }
            }
        }
    }
    return packages;
}

// Helper: Show Loading
function setLoading(isLoading, message = 'Processing...') {
    if (isLoading) {
        loadingMessage.innerText = message;
        loadingOverlay.classList.remove('hidden');
    } else {
        loadingOverlay.classList.add('hidden');
    }
}

// 1. Check Updates
document.getElementById('btn-check-updates').addEventListener('click', async () => {
    // Prevent double loading if already loading? 
    // But simple implementation is fine.
    
    setLoading(true, 'Checking for updates...');
    containers.updates.innerHTML = '';
    
    try {
        const result = await window.winget.checkUpdates();
        if (result.error) {
            console.error(result.error);
        }

        const packages = parseWingetOutput(result.stdout);
        
        if (packages.length === 0) {
            containers.updates.innerHTML = '<p class="placeholder-text">No verified winget updates available.</p>';
        } else {
            // Optimization: Use DocumentFragment to batch DOM updates
            const fragment = document.createDocumentFragment();
            packages.forEach(pkg => {
                const card = document.createElement('div');
                card.className = 'package-card';
                card.innerHTML = `
                    <div class="package-info">
                        <h3>${pkg.name}</h3>
                        <p>ID: ${pkg.id}</p>
                        <p>Current: ${pkg.version} <span style="margin: 0 5px;">&rarr;</span> New: <strong>${pkg.available}</strong></p>
                    </div>
                    <div class="package-actions">
                        <button class="action-btn" onclick="updatePackage('${pkg.id}')">Update</button>
                    </div>
                `;
                fragment.appendChild(card);
            });
            containers.updates.appendChild(fragment);
        }

    } catch (error) {
        containers.updates.innerHTML = `<p class="placeholder-text" style="color: red;">Error: ${error.message}</p>`;
    } finally {
        setLoading(false);
    }
});

async function updatePackage(id) {
    if (!confirm(`Are you sure you want to update ${id}?`)) return;
    
    setLoading(true, `Updating ${id}...`);
    try {
        const result = await window.winget.upgradePackage(id);
        alert(result.stdout || result.stderr);
        // Refresh updates list
        document.getElementById('btn-check-updates').click();
    } catch (error) {
        alert(`Error: ${error.message}`);
    } finally {
        setLoading(false);
    }
}

// 2. List Installed
document.getElementById('btn-refresh-installed').addEventListener('click', loadInstalledPackages);

async function loadInstalledPackages() {
    setLoading(true, 'Loading installed packages...');
    containers.installed.innerHTML = '';

    try {
        const result = await window.winget.listInstalled();
        const packages = parseWingetOutput(result.stdout);

        if (packages.length === 0) {
            containers.installed.innerHTML = '<p class="placeholder-text">No verified winget packages found.</p>';
        } else {
            // Optimization: Use DocumentFragment to batch DOM updates
            const fragment = document.createDocumentFragment();
            packages.forEach(pkg => {
                const card = document.createElement('div');
                card.className = 'package-card';
                card.innerHTML = `
                    <div class="package-info">
                        <h3>${pkg.name}</h3>
                        <p>ID: ${pkg.id}</p>
                        <p>Version: ${pkg.version}</p>
                    </div>
                    <div class="package-actions">
                         <button class="danger-btn" onclick="uninstallPackage('${pkg.id}')">Uninstall</button>
                    </div>
                `;
                fragment.appendChild(card);
            });
            containers.installed.appendChild(fragment);
        }
    } catch (error) {
        containers.installed.innerHTML = `<p class="placeholder-text" style="color: red;">Error: ${error.message}</p>`;
    } finally {
        setLoading(false);
    }
}

async function uninstallPackage(id) {
    if (!confirm(`Are you sure you want to uninstall ${id}? This action cannot be undone.`)) return;

    setLoading(true, `Uninstalling ${id}...`);
    try {
        const result = await window.winget.uninstall(id);
        alert(result.stdout || result.stderr);
        loadInstalledPackages();
    } catch (error) {
        alert(`Error: ${error.message}`);
    } finally {
        setLoading(false);
    }
}

// 3. Search
document.getElementById('btn-search').addEventListener('click', async () => {
    const query = document.getElementById('search-input').value;
    if (!query) return;

    setLoading(true, `Searching for "${query}"...`);
    containers.search.innerHTML = '';

    try {
        const result = await window.winget.search(query);
        const packages = parseWingetOutput(result.stdout);

        if (packages.length === 0) {
            containers.search.innerHTML = '<p class="placeholder-text">No verified packages found.</p>';
        } else {
            // Optimization: Use DocumentFragment to batch DOM updates
            const fragment = document.createDocumentFragment();
            packages.forEach(pkg => {
                const card = document.createElement('div');
                card.className = 'package-card';
                card.innerHTML = `
                    <div class="package-info">
                        <h3>${pkg.name}</h3>
                        <p>ID: ${pkg.id}</p>
                        <p>Version: ${pkg.version}</p>
                        <p>Source: ${pkg.source || 'Unknown'}</p>
                    </div>
                    <div class="package-actions">
                        <button class="primary-btn" onclick="installPackage('${pkg.id}')">Install</button>
                    </div>
                `;
                fragment.appendChild(card);
            });
            containers.search.appendChild(fragment);
        }
    } catch (error) {
        containers.search.innerHTML = `<p class="placeholder-text" style="color: red;">Error: ${error.message}</p>`;
    } finally {
        setLoading(false);
    }
});

async function installPackage(id) {
    if (!confirm(`Are you sure you want to install ${id}?`)) return;

    setLoading(true, `Installing ${id}...`);
    try {
        const result = await window.winget.install(id);
        alert(result.stdout || result.stderr);
    } catch (error) {
        alert(`Error: ${error.message}`);
    } finally {
        setLoading(false);
    }
}

// 4. Backup & Restore
let importedPackages = [];
let exportablePackages = [];

// --- Export Logic ---

document.getElementById('btn-export').addEventListener('click', async () => {
    setLoading(true, 'Fetching packages to export...');
    try {
        // Get current installed packages
        const result = await window.winget.listInstalled();
        const packages = parseWingetOutput(result.stdout);

        if (packages.length === 0) {
            alert('No verified packages found to export.');
            return;
        }

        exportablePackages = packages;
        renderExportList(packages);
        document.getElementById('export-preview-area').classList.remove('hidden');
        document.getElementById('cb-select-all-export').checked = true;
    } catch (error) {
        alert(`Failed to fetch packages: ${error.message}`);
    } finally {
        setLoading(false);
    }
});

function renderExportList(packages) {
    const container = containers.exportList;
    container.innerHTML = '';
    
    // Optimization: Use DocumentFragment to batch DOM updates
    const fragment = document.createDocumentFragment();
    packages.forEach((pkg, index) => {
        const card = document.createElement('div');
        card.className = 'package-card';
        card.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" id="export-cb-${index}" class="export-cb" checked>
                <div class="package-info">
                    <h3>${pkg.name}</h3>
                    <p>ID: ${pkg.id}</p>
                    <p>Version: ${pkg.version}</p>
                </div>
            </div>
        `;
        fragment.appendChild(card);
    });
    container.appendChild(fragment);
}

// Select All - Export
document.getElementById('cb-select-all-export').addEventListener('change', (e) => {
    const checkboxes = document.querySelectorAll('.export-cb');
    checkboxes.forEach(cb => cb.checked = e.target.checked);
});

// Confirm Export
document.getElementById('btn-confirm-export').addEventListener('click', async () => {
    const selectedPackages = [];
    const checkboxes = document.querySelectorAll('.export-cb');
    
    checkboxes.forEach((cb, index) => {
        if (cb.checked) {
            selectedPackages.push(exportablePackages[index]);
        }
    });

    if (selectedPackages.length === 0) {
        alert('Please select at least one package to export.');
        return;
    }

    setLoading(true, 'Exporting packages...');
    try {
        const exportResult = await window.winget.exportPackages(selectedPackages);
        if (exportResult.success) {
            alert(exportResult.message);
            document.getElementById('export-preview-area').classList.add('hidden');
        } else {
            if (exportResult.message !== 'Export cancelled.') {
                alert(exportResult.message);
            }
        }
    } catch (error) {
        alert(`Export failed: ${error.message}`);
    } finally {
        setLoading(false);
    }
});

// Cancel Export
document.getElementById('btn-cancel-export').addEventListener('click', () => {
    document.getElementById('export-preview-area').classList.add('hidden');
    exportablePackages = [];
});


// --- Import Logic ---

document.getElementById('btn-import').addEventListener('click', async () => {
    setLoading(true, 'Reading backup file...');
    try {
        const result = await window.winget.importPackages();
        
        if (!result.success) {
            if (result.message !== 'Import cancelled.') {
                alert(result.message);
            }
            return;
        }

        importedPackages = result.packages;
        renderImportList(importedPackages);
        
        // Show preview area
        document.getElementById('import-preview-area').classList.remove('hidden');
        document.getElementById('import-log').innerHTML = ''; // Clear log
        document.getElementById('cb-select-all-import').checked = true;

    } catch (error) {
        alert(`Import error: ${error.message}`);
    } finally {
        setLoading(false);
    }
});

function renderImportList(packages) {
    const container = containers.importList;
    container.innerHTML = '';
    
    if (packages.length === 0) {
        container.innerHTML = '<p class="placeholder-text">No packages in file.</p>';
        return;
    }

    // Optimization: Use DocumentFragment to batch DOM updates
    const fragment = document.createDocumentFragment();
    packages.forEach((pkg, index) => {
        const card = document.createElement('div');
        card.className = 'package-card';
        card.innerHTML = `
            <div style="display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" id="import-cb-${index}" class="import-cb" checked>
                <div class="package-info">
                    <h3>${pkg.name}</h3>
                    <p>ID: ${pkg.id}</p>
                    <p>Version: ${pkg.version}</p>
                </div>
            </div>
            <div class="package-actions">
                <span class="status-badge" id="status-${pkg.id}">Pending</span>
            </div>
        `;
        fragment.appendChild(card);
    });
    container.appendChild(fragment);
}

// Select All - Import
document.getElementById('cb-select-all-import').addEventListener('change', (e) => {
    const checkboxes = document.querySelectorAll('.import-cb');
    checkboxes.forEach(cb => cb.checked = e.target.checked);
});

// Helper: Log to Import Log Area
function logToImport(message) {
    const logDiv = document.getElementById('import-log');
    const line = document.createElement('div');
    line.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
    logDiv.appendChild(line);
    logDiv.scrollTop = logDiv.scrollHeight;
}

// Cancel Import
document.getElementById('btn-cancel-import').addEventListener('click', () => {
    document.getElementById('import-preview-area').classList.add('hidden');
    importedPackages = [];
});

// Install Selected
document.getElementById('btn-install-selected').addEventListener('click', async () => {
    // Filter selected packages
    const selectedPackagesToInstall = [];
    const checkboxes = document.querySelectorAll('.import-cb');
    
    checkboxes.forEach((cb, index) => {
        if (cb.checked) {
            selectedPackagesToInstall.push(importedPackages[index]);
        }
    });

    if (selectedPackagesToInstall.length === 0) {
        alert('Please select at least one package to install.');
        return;
    }

    if (!confirm(`This will install ${selectedPackagesToInstall.length} packages one by one. Continue?`)) return;

    const logDiv = document.getElementById('import-log');
    
    // Disable inputs during installation
    checkboxes.forEach(cb => cb.disabled = true);
    document.getElementById('btn-install-selected').disabled = true;

    for (const pkg of selectedPackagesToInstall) {
        const statusBadge = document.getElementById(`status-${pkg.id}`);
        statusBadge.innerText = 'Installing...';
        statusBadge.style.color = 'blue';
        
        logToImport(`Installing ${pkg.name} (${pkg.id})...`);
        
        // Scroll log to bottom
        logDiv.scrollTop = logDiv.scrollHeight;

        try {
            const result = await window.winget.install(pkg.id);
            if (result.error) {
                statusBadge.innerText = 'Failed';
                statusBadge.style.color = 'red';
                logToImport(`Failed to install ${pkg.id}: ${result.error.message}`);
            } else {
                statusBadge.innerText = 'Installed';
                statusBadge.style.color = 'green';
                logToImport(`Successfully installed ${pkg.name}`);
            }
        } catch (error) {
            statusBadge.innerText = 'Error';
            statusBadge.style.color = 'red';
            logToImport(`Error installing ${pkg.id}: ${error.message}`);
        }
    }
    
    alert('Batch installation completed. Check logs for details.');
    
    // Re-enable (optional, but good UX if they want to retry failures or install others? 
    // Usually a fresh import or reload is cleaner, but let's re-enable for now)
    document.getElementById('btn-install-selected').disabled = false;
    checkboxes.forEach(cb => cb.disabled = false);
});

function log(message) {
    const logDiv = document.getElementById('import-log');
    const entry = document.createElement('div');
    entry.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
    logDiv.appendChild(entry);
}

// Expose functions to window for inline onclick handlers
window.updatePackage = updatePackage;
window.uninstallPackage = uninstallPackage;
window.installPackage = installPackage;
window.showSection = showSection;
