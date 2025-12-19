import '../models/winget_package.dart';
import '../src/rust/api/simple.dart' as rust;

class WingetService {
  Future<List<WingetPackage>> getInstalledPackages() async {
    final rustPackages = await rust.listPackages();
    return rustPackages.map((item) => WingetPackage(
      name: item.name,
      id: item.id,
      version: item.version,
      available: item.availableVersion,
      source: item.source,
      isInstalled: true,
    )).toList();
  }

  Future<List<WingetPackage>> getUpdatablePackages() async {
    final rustPackages = await rust.listUpdatablePackages();
    return rustPackages.map((item) => WingetPackage(
      name: item.name,
      id: item.id,
      version: item.version,
      available: item.availableVersion,
      source: item.source,
      isInstalled: true,
    )).toList();
  }

  Future<List<WingetPackage>> searchPackages(String query) async {
    if (query.isEmpty) return [];
    final rustPackages = await rust.searchPackages(query: query);
    return rustPackages.map((item) => WingetPackage(
      name: item.name,
      id: item.id,
      version: item.version,
      available: item.availableVersion,
      source: item.source,
    )).toList();
  }

  Future<bool> upgradePackage(String id) async => rust.upgradePackage(id: id);

  Future<bool> installPackage(String id) async => rust.installPackage(id: id);

  Future<bool> uninstallPackage(String id) async => rust.uninstallPackage(id: id);

  Future<List<bool>> installPackages(List<String> ids) async => rust.installPackages(ids: ids);

  Future<void> exportPackages(
    List<WingetPackage> packages,
    String filePath,
  ) async {
    try {
      final rustPackages = packages.map((e) => rust.WingetPackage(
        name: e.name,
        id: e.id,
        version: e.version,
        availableVersion: e.available,
        source: e.source,
      )).toList();
      
      await rust.exportPackages(packages: rustPackages, filePath: filePath);
    } catch (e) {
      throw Exception('Failed to export packages: $e');
    }
  }

  Future<List<WingetPackage>> importPackages(String filePath) async {
    try {
      final rustPackages = await rust.importPackages(filePath: filePath);
      return rustPackages.map((item) => WingetPackage(
        name: item.name,
        id: item.id,
        version: item.version,
        available: item.availableVersion,
        source: item.source,
      )).toList();
    } catch (e) {
      throw Exception('Failed to import packages: $e');
    }
  }
}
