import 'package:flutter/material.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import '../models/configuration.dart';
import '../models/unit_type.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/language_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/enhanced_snackbar.dart';
import '../screens/notification_settings_screen.dart';
import '../screens/pin_settings_screen.dart';
import '../screens/backup_sync_screen.dart';
import 'package:provider/provider.dart';
import '../utils/app_spacing.dart';

class EnhancedConfigurationScreen extends StatefulWidget {
  const EnhancedConfigurationScreen({super.key});

  @override
  State<EnhancedConfigurationScreen> createState() =>
      _EnhancedConfigurationScreenState();
}

class _EnhancedConfigurationScreenState
    extends State<EnhancedConfigurationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  Configuration? _configuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);
    try {
      final config = await _databaseService.getConfiguration();
      setState(() {
        _configuration = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        EnhancedSnackBar.showError(
          context: context,
          message: 'Erreur lors du chargement: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: ModernAppBar(title: localizations.configuration),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.configuration,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    'Personnalisez l\'application: tarifs, devise, apparence, langue, notifications et gestion des données.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.start,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Section Tarification
            _buildSectionCard(
              title: 'Tarification',
              icon: Icons.attach_money_rounded,
              children: [
                _buildConfigTile(
                  title: 'Tarif de base',
                  subtitle:
                      '${_configuration?.tarifBase.toStringAsFixed(2) ?? '0'} ${_configuration?.devise ?? 'FCFA'}/unité',
                  icon: Icons.price_change_rounded,
                  onTap: () => _showTarifDialog(),
                ),
                _buildConfigTile(
                  title: 'Devise',
                  subtitle: _configuration?.devise ?? 'FCFA',
                  icon: Icons.currency_exchange_rounded,
                  onTap: () => _showDeviseDialog(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Apparence
            _buildSectionCard(
              title: 'Apparence',
              icon: Icons.palette_rounded,
              children: [
                Consumer<ThemeService>(
                  builder: (context, themeService, child) {
                    return _buildConfigTile(
                      title: 'Thème',
                      subtitle: _getThemeText(themeService.themeMode),
                      icon: Icons.dark_mode_rounded,
                      onTap: () => _showThemeDialog(themeService),
                    );
                  },
                ),
                Consumer<LanguageService>(
                  builder: (context, languageService, child) {
                    return _buildConfigTile(
                      title: 'Langue',
                      subtitle: _getLanguageText(languageService.currentLocale),
                      icon: Icons.language_rounded,
                      onTap: () => _showLanguageDialog(languageService),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Notifications
            _buildSectionCard(
              title: 'Notifications',
              icon: Icons.notifications_rounded,
              children: [
                _buildConfigTile(
                  title: 'Paramètres de notification',
                  subtitle: 'Gérer les rappels et alertes',
                  icon: Icons.notification_important_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigTile(
                  title: 'Code PIN',
                  subtitle: 'Activer, modifier ou supprimer le code PIN',
                  icon: Icons.lock_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PinSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section Données
            _buildSectionCard(
              title: 'Données',
              icon: Icons.storage_rounded,
              children: [
                _buildConfigTile(
                  title: 'Backup & Synchronisation',
                  subtitle: 'Sauvegarder et restaurer vos données',
                  icon: Icons.cloud_sync_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BackupSyncScreen(),
                      ),
                    );
                  },
                ),
                _buildConfigTile(
                  title: 'Sauvegarder les données',
                  subtitle: 'Exporter vos données',
                  icon: Icons.backup_rounded,
                  onTap: () => _showBackupDialog(),
                ),
                _buildConfigTile(
                  title: 'Restaurer les données',
                  subtitle: 'Importer des données',
                  icon: Icons.restore_rounded,
                  onTap: () => _showRestoreDialog(),
                ),
                _buildConfigTile(
                  title: 'Réinitialiser l\'application',
                  subtitle: 'Supprimer toutes les données',
                  icon: Icons.delete_forever_rounded,
                  onTap: () => _showResetDialog(),
                  isDestructive: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Section À propos
            _buildSectionCard(
              title: 'À propos',
              icon: Icons.info_rounded,
              children: [
                _buildConfigTile(
                  title: 'Version de l\'application',
                  subtitle: '1.0.0',
                  icon: Icons.info_outline_rounded,
                  onTap: () => _showAboutDialog(),
                ),
                _buildConfigTile(
                  title: 'Conditions d\'utilisation',
                  subtitle: 'Lire les conditions',
                  icon: Icons.description_rounded,
                  onTap: () => _showTermsDialog(),
                ),
                _buildConfigTile(
                  title: 'Politique de confidentialité',
                  subtitle: 'Lire la politique',
                  icon: Icons.privacy_tip_rounded,
                  onTap: () => _showPrivacyDialog(),
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildConfigTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isDestructive ? Colors.red : colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isDestructive ? Colors.red : null,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getThemeText(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Clair';
      case ThemeMode.dark:
        return 'Sombre';
      case ThemeMode.system:
        return 'Système';
    }
  }

  String _getLanguageText(Locale locale) {
    switch (locale.languageCode) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      default:
        return 'Français';
    }
  }

  void _showTarifDialog() {
    final controller = TextEditingController(
      text: _configuration?.tarifBase.toString() ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tarif de base',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Définissez le tarif par défaut appliqué à tous les locataires',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Tarif par unité',
                  suffixText: _configuration?.devise ?? 'FCFA',
                  prefixIcon: const Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _saveTarif(controller.text),
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeviseDialog() {
    final controller = TextEditingController(
      text: _configuration?.devise ?? 'FCFA',
    );

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Devise',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez la devise utilisée dans l\'application',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Devise',
                  hintText: 'Ex: FCFA, EUR, USD',
                  prefixIcon: Icon(Icons.currency_exchange_rounded),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => _saveDevise(controller.text),
                    child: const Text('Sauvegarder'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(ThemeService themeService) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Thème',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez l\'apparence de l\'application',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ...ThemeMode.values.map((mode) {
                return RadioListTile<ThemeMode>(
                  title: Text(_getThemeText(mode)),
                  value: mode,
                  groupValue: themeService.themeMode,
                  onChanged: (value) {
                    if (value != null) {
                      themeService.setTheme(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(LanguageService languageService) {
    final languages = [
      {'code': 'fr', 'name': 'Français'},
      {'code': 'en', 'name': 'English'},
    ];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Langue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choisissez la langue de l\'application',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              ...languages.map((lang) {
                final locale = Locale(lang['code']!);
                return RadioListTile<Locale>(
                  title: Text(lang['name']!),
                  value: locale,
                  groupValue: languageService.currentLocale,
                  onChanged: (value) {
                    if (value != null) {
                      languageService.changeLanguage(value);
                      Navigator.pop(context);
                    }
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveTarif(String value) async {
    final tarif = double.tryParse(value);
    if (tarif == null || tarif <= 0) {
      EnhancedSnackBar.showError(
        context: context,
        message: 'Veuillez saisir un tarif valide',
      );
      return;
    }

    try {
      final newConfig = Configuration(
        id: _configuration?.id,
        tarifBase: tarif,
        devise: _configuration?.devise ?? 'FCFA',
        defaultUnitId: _configuration?.defaultUnitId,
        defaultUnitType: _configuration?.defaultUnitType ?? UnitType.water,
        dateModification: DateTime.now(),
      );

      await _databaseService.updateConfiguration(newConfig);
      Navigator.pop(context);
      await _loadConfiguration();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: 'Tarif mis à jour avec succès',
      );
    } catch (e) {
      EnhancedSnackBar.showError(
        context: context,
        message: 'Erreur lors de la sauvegarde: $e',
      );
    }
  }

  Future<void> _saveDevise(String value) async {
    if (value.trim().isEmpty) {
      EnhancedSnackBar.showError(
        context: context,
        message: 'Veuillez saisir une devise',
      );
      return;
    }

    try {
      final newConfig = Configuration(
        id: _configuration?.id,
        tarifBase: _configuration?.tarifBase ?? 0,
        devise: value.trim(),
        defaultUnitId: _configuration?.defaultUnitId,
        defaultUnitType: _configuration?.defaultUnitType ?? UnitType.water,
        dateModification: DateTime.now(),
      );

      await _databaseService.updateConfiguration(newConfig);
      Navigator.pop(context);
      await _loadConfiguration();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: 'Devise mise à jour avec succès',
      );
    } catch (e) {
      EnhancedSnackBar.showError(
        context: context,
        message: 'Erreur lors de la sauvegarde: $e',
      );
    }
  }

  void _showBackupDialog() {
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Fonctionnalité de sauvegarde - En cours de développement',
    );
  }

  void _showRestoreDialog() {
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Fonctionnalité de restauration - En cours de développement',
    );
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Réinitialiser l\'application',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Cette action supprimera définitivement toutes vos données. Cette action est irréversible.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        EnhancedSnackBar.showInfo(
                          context: context,
                          message:
                              'Réinitialisation - En cours de développement',
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Réinitialiser'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: 'Rentilax Tracker',
        applicationVersion: '1.0.0',
        applicationIcon: const Icon(Icons.home_rounded, size: 48),
        children: const [
          Text(
              'Application de gestion des locataires et relevés de consommation.'),
        ],
      ),
    );
  }

  void _showTermsDialog() {
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Conditions d\'utilisation - En cours de développement',
    );
  }

  void _showPrivacyDialog() {
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Politique de confidentialité - En cours de développement',
    );
  }
}
