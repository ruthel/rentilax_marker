import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? text;

  const AppLogo({
    super.key,
    this.size = 120,
    this.showText = false,
    this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/Rentilax logo.jpg',
          width: size,
          height: size,
        ),
        if (showText) ...[
          const SizedBox(height: 12),
          Text(
            text ?? 'Rentilax Marker',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

// Widget simplifié pour les petites tailles
class AppLogoIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const AppLogoIcon({
    super.key,
    this.size = 24,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/Rentilax logo.png',
      width: size,
      height: size,
      color: color, // Apply color filter if color is provided
    );
  }
}
