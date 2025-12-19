import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/winget_package.dart';
import '../services/winget_service.dart';

class PackageProvider with ChangeNotifier {
  final WingetService _service = WingetService();

  List<WingetPackage> _installedPackages = [];
  List<WingetPackage> _updatablePackages = [];
  List<WingetPackage> _searchResults = [];
  List<WingetPackage> _importedPackages = [];
  
  List<WingetPackage>? _filteredInstalledCache;
  List<WingetPackage>? _filteredUpdatableCache;
  List<WingetPackage>? _filteredSearchCache;

  bool _isLoading = false;
  String? _loadingId;
  String? _error;
  String _searchQuery = '';
  String _activeTab = 'installed';
  bool _filterTrusted = false;
  final Set<String> _selectedPackageIds = {};

  List<WingetPackage> get installedPackages => _filterTrusted ? (_filteredInstalledCache ??= _filterTrustedPackages(_installedPackages)) : _installedPackages;
  List<WingetPackage> get updatablePackages => _filterTrusted ? (_filteredUpdatableCache ??= _filterTrustedPackages(_updatablePackages)) : _updatablePackages;
  List<WingetPackage> get searchResults => _filterTrusted ? (_filteredSearchCache ??= _filterTrustedPackages(_searchResults)) : _searchResults;
  List<WingetPackage> get importedPackages => _importedPackages;
  Set<String> get selectedPackageIds => _selectedPackageIds;
  
  void _clearCache() {
    _filteredInstalledCache = null;
    _filteredUpdatableCache = null;
    _filteredSearchCache = null;
  }
  bool get isLoading => _isLoading;
  String? get loadingId => _loadingId;
  String? get error => _error;
  String get searchQuery => _searchQuery;
  String get activeTab => _activeTab;
  bool get filterTrusted => _filterTrusted;

  void toggleSelection(String id) {
    if (_selectedPackageIds.contains(id)) {
      _selectedPackageIds.remove(id);
    } else {
      _selectedPackageIds.add(id);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedPackageIds.clear();
    notifyListeners();
  }

  void selectAll(List<WingetPackage> packages) {
    final allSelected = packages.every((p) => _selectedPackageIds.contains(p.id));
    if (allSelected) {
      for (final p in packages) {
        _selectedPackageIds.remove(p.id);
      }
    } else {
      for (final p in packages) {
        _selectedPackageIds.add(p.id);
      }
    }
    notifyListeners();
  }

  List<WingetPackage> _filterTrustedPackages(List<WingetPackage> packages) {
    const trustedKeywords = ['microsoft', 'google', 'mozilla', 'adobe', 'github'];
    return packages.where((pkg) {
      final idLower = pkg.id.toLowerCase();
      final nameLower = pkg.name.toLowerCase();
      return trustedKeywords.any((k) => idLower.contains(k) || nameLower.contains(k));
    }).toList();
  }

  void toggleTrustedFilter() {
    _filterTrusted = !_filterTrusted;
    _clearCache();
    notifyListeners();
  }

  Future<void> setActiveTab(String tab) async {
    _activeTab = tab;
    _error = null;
    _selectedPackageIds.clear();
    
    if (tab == 'updates') {
      await loadUpdatablePackages();
    } else if (tab == 'transfer') {
      // Ensure we have the latest installed packages for filtering during import
      if (_installedPackages.isEmpty) {
        await loadInstalledPackages();
      }
    }
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> loadInstalledPackages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _installedPackages = await _service.getInstalledPackages();
      _clearCache();
    } catch (e) {
      _error = 'Failed to load installed packages.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUpdatablePackages() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _updatablePackages = await _service.getUpdatablePackages();
      _clearCache();
    } catch (e) {
      _error = 'Failed to load updates.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchPackages(String query) async {
    if (query.isEmpty) return;

    _isLoading = true;
    _error = null;
    _activeTab = 'search';
    _searchQuery = query;
    notifyListeners();

    try {
      _searchResults = await _service.searchPackages(query);
      _clearCache();
    } catch (e) {
      _error = 'Search failed. Please try again.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradePackage(String id) async {
    _loadingId = id;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.upgradePackage(id);
      if (success) {
        if (_activeTab == 'updates') {
          await loadUpdatablePackages();
        } else {
          await loadInstalledPackages();
        }
      } else {
        _error = 'Upgrade failed after retries.';
      }
    } catch (e) {
      _error = 'An error occurred during upgrade.';
    } finally {
      _loadingId = null;
      notifyListeners();
    }
  }

  Future<void> upgradeAll() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      for (final pkg in _updatablePackages) {
        _loadingId = pkg.id;
        notifyListeners();
        await _service.upgradePackage(pkg.id);
      }
      await loadUpdatablePackages();
    } catch (e) {
      _error = 'Some upgrades might have failed.';
    } finally {
      _loadingId = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> installPackage(String id) async {
    _loadingId = id;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.installPackage(id);
      if (success) {
        await loadInstalledPackages();
      } else {
        _error = 'Installation failed.';
      }
    } catch (e) {
      _error = 'An error occurred during installation.';
    } finally {
      _loadingId = null;
      notifyListeners();
    }
  }

  Future<void> uninstallPackage(String id) async {
    _loadingId = id;
    _error = null;
    notifyListeners();

    try {
      final success = await _service.uninstallPackage(id);
      if (success) {
        await loadInstalledPackages();
      } else {
        _error = 'Uninstall failed.';
      }
    } catch (e) {
      _error = 'An error occurred during uninstall.';
    } finally {
      _loadingId = null;
      notifyListeners();
    }
  }

  Future<void> exportMyList() async {
    final selectedPackages = _installedPackages.where((pkg) => _selectedPackageIds.contains(pkg.id)).toList();
    
    if (selectedPackages.isEmpty) {
      _error = 'Please select at least one package to export.';
      notifyListeners();
      return;
    }

    String? outputFile = await FilePicker.platform.saveFile(
      dialogTitle: 'Export Selected Packages',
      fileName: 'packages.ewm',
      type: FileType.custom,
      allowedExtensions: ['ewm'],
    );

    if (outputFile == null) return;

    if (!outputFile.endsWith('.ewm')) {
      outputFile += '.ewm';
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _service.exportPackages(selectedPackages, outputFile);
      _selectedPackageIds.clear();
    } catch (e) {
      _error = 'Failed to export list: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> importMyList() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['ewm'],
    );

    if (result == null || result.files.single.path == null) return;

    _isLoading = true;
    _error = null;
    _importedPackages = [];
    _selectedPackageIds.clear();
    notifyListeners();

    try {
      final imported = await _service.importPackages(result.files.single.path!);
      
      // Filter out packages that are already installed
      final installedIds = _installedPackages.map((e) => e.id).toSet();
      _importedPackages = imported.where((pkg) => !installedIds.contains(pkg.id)).toList();
      
      if (imported.isEmpty) {
        _error = 'No packages found in the selected file.';
      } else if (_importedPackages.isEmpty) {
        _error = 'All packages in the file are already installed.';
      }
    } catch (e) {
      _error = 'Failed to load import file: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> installSelectedImported() async {
    final toInstall = _importedPackages
        .where((pkg) => _selectedPackageIds.contains(pkg.id))
        .map((e) => e.id)
        .toList();

    if (toInstall.isEmpty) {
      _error = 'Please select at least one package to install.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.installPackages(toInstall);
      await loadInstalledPackages();
      _importedPackages.clear();
      _selectedPackageIds.clear();
      _activeTab = 'installed';
    } catch (e) {
      _error = 'Failed to install selected packages: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
