import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/winget_package.dart';
import '../providers/package_provider.dart';
import 'package_list_item.dart';

class PackageTable extends StatelessWidget {
  final List<WingetPackage> packages;
  final bool showSelection;

  const PackageTable({
    super.key,
    required this.packages,
    this.showSelection = false,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PackageProvider>();
    
    if (packages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 16),
            Text(
              'No packages found',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isSmallScreen = constraints.maxWidth < 800;
        final bool isVerySmallScreen = constraints.maxWidth < 600;

        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.02),
                border: Border(
                  bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
                ),
              ),
              child: Row(
                children: [
                  if (showSelection)
                    SizedBox(
                      width: 48,
                      child: Checkbox(
                        value: packages.isNotEmpty && packages.every((p) => provider.selectedPackageIds.contains(p.id)),
                        onChanged: (_) => provider.selectAll(packages),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                    ),
                  const Expanded(flex: 4, child: _HeaderCell(label: 'NAME')),
                  if (!isVerySmallScreen)
                    const Expanded(flex: 4, child: _HeaderCell(label: 'ID')),
                  const Expanded(flex: 2, child: _HeaderCell(label: 'VERSION')),
                  if (!isSmallScreen)
                    const Expanded(flex: 2, child: _HeaderCell(label: 'AVAILABLE')),
                  const Expanded(
                    flex: 2,
                    child: _HeaderCell(label: 'ACTIONS', alignRight: true),
                  ),
                ],
              ),
            ),
            // Table Body
            Expanded(
              child: ListView.builder(
                itemCount: packages.length,
                itemBuilder: (context, index) => PackageListItem(
                  package: packages[index],
                  isSmallScreen: isSmallScreen,
                  isVerySmallScreen: isVerySmallScreen,
                  showSelection: showSelection,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final bool alignRight;

  const _HeaderCell({required this.label, this.alignRight = false});

  @override
  Widget build(BuildContext context) => Text(
        label,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      );
}
