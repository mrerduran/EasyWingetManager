import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/package_provider.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();

    return Container(
      width: 260,
      color: const Color(0xFF1E293B),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Row(
              children: [
                Icon(Icons.apps, color: Color(0xFF3B82F6), size: 28),
                SizedBox(width: 12),
                Text(
                  'Easy Winget',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _SidebarButton(
                    icon: Icons.dashboard,
                    label: 'Installed',
                    isActive: provider.activeTab == 'installed',
                    onTap: () => provider.setActiveTab('installed'),
                  ),
                  const SizedBox(height: 8),
                  _SidebarButton(
                    icon: Icons.update,
                    label: 'Updates',
                    isActive: provider.activeTab == 'updates',
                    onTap: () => provider.setActiveTab('updates'),
                  ),
                  const SizedBox(height: 8),
                  _SidebarButton(
                    icon: Icons.search,
                    label: 'Search',
                    isActive: provider.activeTab == 'search',
                    onTap: () => provider.setActiveTab('search'),
                  ),
                  const SizedBox(height: 8),
                  _SidebarButton(
                    icon: Icons.swap_horiz,
                    label: 'Import / Export',
                    isActive: provider.activeTab == 'transfer',
                    onTap: () => provider.setActiveTab('transfer'),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFF334155)),
                  const SizedBox(height: 16),
                  // Trusted Filter Toggle
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => provider.toggleTrustedFilter(),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(
                              provider.filterTrusted ? Icons.verified : Icons.verified_outlined,
                              size: 20,
                              color: provider.filterTrusted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Trusted Only',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            Switch(
                               value: provider.filterTrusted,
                               onChanged: (_) => provider.toggleTrustedFilter(),
                               activeThumbColor: const Color(0xFF3B82F6),
                               materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _SidebarButton(
              icon: Icons.settings,
              label: 'Settings',
              isActive: false,
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF3B82F6) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isActive
                      ? const Color(0xFF0F172A)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
