import 'dart:async';
import 'package:flutter/material.dart' hide ListTile;
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'providers/package_provider.dart';
import 'widgets/sidebar.dart';
import 'widgets/package_table.dart';
import 'src/rust/frb_generated.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
  await windowManager.ensureInitialized();

  const WindowOptions windowOptions = WindowOptions(
    size: Size(1200, 800),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    title: 'Easy Winget Manager',
  );

  unawaited(windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  }));

  runApp(
    ChangeNotifierProvider(
      create: (_) => PackageProvider()..loadInstalledPackages(),
      child: const EasyWingetApp(),
    ),
  );
}

class EasyWingetApp extends StatelessWidget {
  const EasyWingetApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Easy Winget Manager',
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF0F172A),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF3B82F6),
            secondary: Color(0xFF94A3B8),
            surface: Color(0xFF1E293B),
            onPrimary: Colors.white,
            error: Color(0xFFF43F5E),
          ),
          useMaterial3: true,
        ),
        home: const MainScreen(),
      );
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<PackageProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();

    return Scaffold(
      body: Row(
        children: [
          const Sidebar(),
          Expanded(
            child: Column(
              children: [
                // Header
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 600),
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onSubmitted: (value) => provider.searchPackages(value),
                            decoration: const InputDecoration(
                              hintText: 'Search packages...',
                              prefixIcon: Icon(Icons.search, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      const Row(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Administrator', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                              Text('System Manager', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                            ],
                          ),
                          SizedBox(width: 16),
                          _UserAvatar(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (provider.error != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 24),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFF43F5E).withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFF43F5E), size: 20),
                                const SizedBox(width: 12),
                                Text(provider.error!, style: const TextStyle(color: Color(0xFFF43F5E), fontWeight: FontWeight.w500)),
                                const Spacer(),
                                TextButton(
                                  onPressed: () => provider.clearError(),
                                  child: const Text('Dismiss', style: TextStyle(color: Color(0xFFF43F5E), fontSize: 12, decoration: TextDecoration.underline)),
                                ),
                              ],
                            ),
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider.activeTab == 'installed'
                                    ? 'Installed Applications'
                                  : provider.activeTab == 'updates'
                                    ? 'Available Updates'
                                    : provider.activeTab == 'search'
                                      ? 'Search results for "${provider.searchQuery}"'
                                      : 'Import / Export Packages',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                provider.activeTab == 'installed'
                                  ? '${provider.installedPackages.length} packages found on your system'
                                  : provider.activeTab == 'updates'
                                    ? '${provider.updatablePackages.length} updates available'
                                    : provider.activeTab == 'search'
                                      ? '${provider.searchResults.length} matches found'
                                      : 'Transfer your package lists between systems',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              if (provider.activeTab == 'transfer')
                                Row(
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => provider.importMyList(),
                                      icon: const Icon(Icons.upload_file, size: 18),
                                      label: const Text('Load File'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF1E293B),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (provider.importedPackages.isNotEmpty)
                                      ElevatedButton.icon(
                                        onPressed: provider.selectedPackageIds.isEmpty ? null : () => provider.installSelectedImported(),
                                        icon: const Icon(Icons.add_task, size: 18),
                                        label: const Text('Install Selected'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF10B981),
                                          foregroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    if (provider.importedPackages.isEmpty)
                                      ElevatedButton.icon(
                                        onPressed: provider.selectedPackageIds.isEmpty ? null : () => provider.exportMyList(),
                                        icon: const Icon(Icons.download, size: 18),
                                        label: const Text('Export Selected'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                          foregroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                  ],
                                ),
                              if (provider.activeTab == 'installed')
                                  ElevatedButton.icon(
                                    onPressed: () => provider.loadInstalledPackages(),
                                    icon: const Icon(Icons.refresh, size: 18),
                                    label: const Text('Refresh List'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E293B),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                    ),
                                  ),
                                if (provider.activeTab == 'updates')
                                  Row(
                                    children: [
                                      ElevatedButton.icon(
                                        onPressed: () => provider.loadUpdatablePackages(),
                                        icon: const Icon(Icons.refresh, size: 18),
                                        label: const Text('Refresh'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF1E293B),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton.icon(
                                        onPressed: provider.updatablePackages.isEmpty ? null : () => provider.upgradeAll(),
                                        icon: const Icon(Icons.system_update_alt, size: 18),
                                        label: const Text('Update All'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF3B82F6),
                                          foregroundColor: const Color(0xFF0F172A),
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        Expanded(
                          child: provider.isLoading
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(color: Color(0xFF3B82F6)),
                                    SizedBox(height: 16),
                                    Text('Fetching packages from Winget...', style: TextStyle(color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              )
                            : Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: PackageTable(
                                  showSelection: provider.activeTab == 'transfer',
                                  packages: provider.activeTab == 'installed'
                                    ? provider.installedPackages
                                    : provider.activeTab == 'updates'
                                      ? provider.updatablePackages
                                      : provider.activeTab == 'search'
                                        ? provider.searchResults
                                        : provider.importedPackages.isNotEmpty
                                          ? provider.importedPackages
                                          : provider.installedPackages,
                                ),
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFFF43F5E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Center(
              child: Text('A', style: TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      );
}
