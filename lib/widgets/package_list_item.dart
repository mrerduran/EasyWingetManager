import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/winget_package.dart';
import '../providers/package_provider.dart';

class PackageListItem extends StatelessWidget {
  final WingetPackage package;
  final bool isSmallScreen;
  final bool isVerySmallScreen;
  final bool showSelection;

  const PackageListItem({
    super.key,
    required this.package,
    this.isSmallScreen = false,
    this.isVerySmallScreen = false,
    this.showSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();
    final isLoading = provider.loadingId == package.id;
    final isSelected = provider.selectedPackageIds.contains(package.id);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withValues(alpha: 0.02) : null,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.03)),
        ),
      ),
      child: Row(
        children: [
          if (showSelection)
            SizedBox(
              width: 48,
              child: Checkbox(
                value: isSelected,
                onChanged: (_) => provider.toggleSelection(package.id),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
              ),
            ),
          Expanded(
            flex: 4,
            child: Text(
              package.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!isVerySmallScreen)
            Expanded(
              flex: 4,
              child: Text(
                package.id,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      package.version,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF94A3B8),
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallScreen)
            Expanded(
              flex: 2,
              child: package.available != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              package.available!,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.bold,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    )
                  : const Text('-', style: TextStyle(color: Color(0xFF475569))),
            ),
          Expanded(
            flex: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Color(0xFF3B82F6),
                    ),
                  )
                else
                  _buildActions(context, provider),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, PackageProvider provider) {
    if (package.isInstalled) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (package.available != null && provider.activeTab == 'updates')
            _ActionButton(
              icon: Icons.upgrade,
              color: const Color(0xFF3B82F6),
              tooltip: 'Upgrade',
              onPressed: () => provider.upgradePackage(package.id),
            ),
          if (package.available != null && provider.activeTab == 'updates')
            const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.delete_outline,
            color: const Color(0xFFF43F5E),
            tooltip: 'Uninstall',
            onPressed: () => provider.uninstallPackage(package.id),
          ),
        ],
      );
    } else {
      return _ActionButton(
        icon: Icons.add_circle_outline,
        color: const Color(0xFF10B981),
        tooltip: 'Install',
        onPressed: () => provider.installPackage(package.id),
      );
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
          ),
        ),
      );
}
