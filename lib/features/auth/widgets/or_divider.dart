import 'package:flutter/material.dart';
import '../../../core/theme/dukani_theme.dart';

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'أو'});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: DukaniColors.ink500)),
        ),
        const Expanded(child: Divider()),
      ],
    );
  }
}
