import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/connectivity_banner.dart';
import '../../core/widgets/dukani_bottom_nav.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shell around every primary bottom-nav destination. Only "الرئيسية" is
/// fully built in this phase — the rest route to a branded placeholder via
/// [goToSection] so the nav bar is fully wired without faking finished work.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  static const _items = [
    DukaniNavItem(icon: LucideIcons.receipt, activeIcon: LucideIcons.receipt, label: 'التقارير'),
    DukaniNavItem(icon: LucideIcons.users, activeIcon: LucideIcons.users, label: 'العملاء'),
    DukaniNavItem(icon: LucideIcons.warehouse, activeIcon: LucideIcons.warehouse, label: 'المخزون'),
    DukaniNavItem(icon: LucideIcons.home, activeIcon: LucideIcons.home, label: 'الرئيسية'),
  ];

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.pushNamed(R.reports);
        break;
      case 1:
        context.pushNamed(R.customers);
        break;
      case 2:
        context.pushNamed(R.inventory);
        break;
      case 3:
        context.goNamed(R.home);
        break;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const SafeArea(bottom: false, child: ConnectivityBanner()),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: DukaniBottomNav(
        currentIndex: 3,
        items: _items,
        onTap: (i) => _onTap(context, i),
        onCenterTap: () => context.pushNamed(R.pos),
      ),
    );
  }
}
