import 'package:flutter/material.dart';

import '../../core/router/app_router.dart';
import '../../core/widgets/dukani_states.dart';

/// Branded stand-in for every section not yet built in this phase. Reached
/// from the home dashboard, drawer, or bottom nav — keeps every button in
/// the app leading somewhere real while the screens are built out in order.
class SectionPlaceholderScreen extends StatelessWidget {
  const SectionPlaceholderScreen({super.key, required this.section});
  final DukaniSection section;

  @override
  Widget build(BuildContext context) {
    return DukaniComingSoon(title: section.titleAr);
  }
}
