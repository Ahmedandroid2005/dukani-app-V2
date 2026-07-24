import 'package:flutter/material.dart';
import '../../../core/theme/dukani_theme.dart';

class SetupProgress extends StatelessWidget {
  const SetupProgress({super.key, required this.step, required this.total});
  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final active = i <= step;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == total - 1 ? 0 : 6),
            height: 6,
            decoration: BoxDecoration(
              color: active ? DukaniColors.forest700 : DukaniColors.ink100,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }
}
