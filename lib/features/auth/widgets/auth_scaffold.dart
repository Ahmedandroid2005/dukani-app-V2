import 'package:flutter/material.dart';
import '../../../core/theme/dukani_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Shared shell for every auth screen: plain white background, a small
/// tinted logo mark, and the title/subtitle/form stacked directly on the
/// page — no dark hero band. Matches the approved white/clean direction:
/// the brand shows up in the accent color and mark, not in a colored panel.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.children,
    this.subtitle,
    this.showLogo = true,
    this.showBack = true,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final bool showLogo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: DukaniColors.paper,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(DukaniSpacing.xl, DukaniSpacing.sm, DukaniSpacing.xl, DukaniSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 36,
                child: showBack
                    ? Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Material(
                          color: DukaniColors.forest50,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.of(context).maybePop(),
                            child: const Padding(
                              padding: EdgeInsets.all(8),
                              child: Icon(LucideIcons.arrowLeft, size: 18, color: DukaniColors.forest700),
                            ),
                          ),
                        ),
                      )
                    : null,
              ),
              if (showLogo) ...[
                const SizedBox(height: DukaniSpacing.lg),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: DukaniColors.forest50, borderRadius: BorderRadius.circular(DukaniRadii.lg)),
                  child: const Icon(LucideIcons.store, size: 28, color: DukaniColors.forest700),
                ),
                const SizedBox(height: DukaniSpacing.lg),
              ] else
                const SizedBox(height: DukaniSpacing.md),
              Text(title, style: textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: textTheme.bodyMedium?.copyWith(color: DukaniColors.ink500)),
              ],
              const SizedBox(height: DukaniSpacing.xxl),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
