import 'package:flutter/material.dart';
import '../utils/app_spacing.dart';

/// Widget pour les titres de section, harmonisé avec le thème global.
class SectionTitle extends StatelessWidget {
  final String text;
  final TextAlign align;
  final EdgeInsetsGeometry? padding;
  final bool isMain;

  const SectionTitle({
    super.key,
    required this.text,
    this.align = TextAlign.left,
    this.padding,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding ?? AppSpacing.section,
      child: Text(
        text,
        style: isMain
            ? theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)
            : theme.textTheme.headlineSmall,
        textAlign: align,
      ),
    );
  }
}
