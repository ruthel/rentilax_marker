import 'package:flutter/material.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/app_logo.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.about,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Logo principal avec animation
            Hero(
              tag: 'app_logo',
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const AppLogo(
                  size: 120,
                  showText: true,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Informations de l'application
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Informations',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    'Version',
                    '1.0.0',
                    Icons.tag_rounded,
                  ),
                  _buildInfoRow(
                    context,
                    'Développé avec',
                    'Flutter & Dart',
                    Icons.code_rounded,
                  ),
                  _buildInfoRow(
                    context,
                    'Base de données',
                    'SQLite',
                    Icons.storage_rounded,
                  ),
                  _buildInfoRow(
                    context,
                    'Design',
                    'Material Design 3',
                    Icons.palette_rounded,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Description de l'application
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: colorScheme.secondary,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Description',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rentilax Tracker est une application moderne de gestion des locataires et de leurs relevés de consommation. Elle permet de suivre facilement les consommations d\'eau, d\'électricité et de gaz, de gérer les paiements et de générer des rapports détaillés.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Fonctionnalités principales
            ModernCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Fonctionnalités',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureItem(
                    context,
                    'Gestion des cités et locataires',
                    Icons.location_city_rounded,
                    Colors.blue,
                  ),
                  _buildFeatureItem(
                    context,
                    'Relevés automatisés avec unités multiples',
                    Icons.assessment_rounded,
                    Colors.green,
                  ),
                  _buildFeatureItem(
                    context,
                    'Calcul automatique des montants',
                    Icons.calculate_rounded,
                    Colors.orange,
                  ),
                  _buildFeatureItem(
                    context,
                    'Gestion des paiements partiels',
                    Icons.payment_rounded,
                    Colors.purple,
                  ),
                  _buildFeatureItem(
                    context,
                    'Rapports PDF détaillés',
                    Icons.picture_as_pdf_rounded,
                    Colors.red,
                  ),
                  _buildFeatureItem(
                    context,
                    'Notifications automatiques',
                    Icons.notifications_rounded,
                    Colors.teal,
                  ),
                  _buildFeatureItem(
                    context,
                    'Interface moderne et intuitive',
                    Icons.design_services_rounded,
                    Colors.indigo,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Copyright et remerciements
            ModernCard(
              child: Column(
                children: [
                  const AppLogoIcon(size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '© 2025 Rentilax Tracker',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Développé avec ❤️ pour simplifier la gestion locative',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    String feature,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feature,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
