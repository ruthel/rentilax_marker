import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/enhanced_snackbar.dart';
import '../services/advanced_notification_service.dart';
import '../utils/app_spacing.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _readingReminders = true;
  bool _paymentReminders = true;
  bool _monthlyReports = true;
  int _reminderDay = 25;
  int _reminderHour = 9;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _readingReminders = prefs.getBool('reading_reminders_enabled') ?? true;
      _paymentReminders = prefs.getBool('payment_reminders_enabled') ?? true;
      _monthlyReports = prefs.getBool('monthly_reports_enabled') ?? true;
      _reminderDay = prefs.getInt('reminder_day') ?? 25;
      _reminderHour = prefs.getInt('reminder_hour') ?? 9;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);

    try {
      await AdvancedNotificationService.updateNotificationSettings(
        readingReminders: _readingReminders,
        paymentReminders: _paymentReminders,
        monthlyReports: _monthlyReports,
        reminderDay: _reminderDay,
        reminderHour: _reminderHour,
      );

      if (mounted) {
        EnhancedSnackBar.showSuccess(
          context: context,
          message: 'Paramètres de notification sauvegardés',
        );
      }
    } catch (e) {
      if (mounted) {
        EnhancedSnackBar.showError(
          context: context,
          message: 'Erreur lors de la sauvegarde: $e',
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: const ModernAppBar(title: 'Notifications'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Paramètres de notification',
        actions: [
          TextButton(
            onPressed: _saveSettings,
            child: const Text('Sauvegarder'),
          ),
        ],
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
                    'Recevez les rappels essentiels au bon moment. Activez les alertes utiles (relevés, paiements, rapports) et choisissez le jour et l\'heure qui vous conviennent.',
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

            // Types de notifications
            _buildSectionCard(
              title: 'Types de notifications',
              icon: Icons.notifications_rounded,
              children: [
                _buildSwitchTile(
                  title: 'Rappels de relevés',
                  subtitle:
                      'Recevoir des rappels pour faire les relevés mensuels',
                  value: _readingReminders,
                  onChanged: (value) {
                    setState(() => _readingReminders = value);
                  },
                  icon: Icons.assessment_rounded,
                ),
                _buildSwitchTile(
                  title: 'Paiements en retard',
                  subtitle: 'Être notifié des paiements en retard',
                  value: _paymentReminders,
                  onChanged: (value) {
                    setState(() => _paymentReminders = value);
                  },
                  icon: Icons.payment_rounded,
                ),
                _buildSwitchTile(
                  title: 'Rapports mensuels',
                  subtitle:
                      'Recevoir une notification quand le rapport mensuel est prêt',
                  value: _monthlyReports,
                  onChanged: (value) {
                    setState(() => _monthlyReports = value);
                  },
                  icon: Icons.bar_chart_rounded,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Paramètres de timing
            _buildSectionCard(
              title: 'Paramètres de timing',
              icon: Icons.schedule_rounded,
              children: [
                _buildSliderTile(
                  title: 'Jour du rappel',
                  subtitle: 'Jour du mois pour recevoir le rappel de relevé',
                  value: _reminderDay.toDouble(),
                  min: 1,
                  max: 28,
                  divisions: 27,
                  onChanged: _readingReminders
                      ? (value) {
                          setState(() => _reminderDay = value.round());
                        }
                      : null,
                  valueLabel: '${_reminderDay}e jour du mois',
                ),
                _buildSliderTile(
                  title: 'Heure du rappel',
                  subtitle: 'Heure à laquelle recevoir les notifications',
                  value: _reminderHour.toDouble(),
                  min: 6,
                  max: 22,
                  divisions: 16,
                  onChanged: _readingReminders
                      ? (value) {
                          setState(() => _reminderHour = value.round());
                        }
                      : null,
                  valueLabel: '${_reminderHour}h00',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Actions
            _buildSectionCard(
              title: 'Actions',
              icon: Icons.settings_rounded,
              children: [
                _buildActionTile(
                  title: 'Tester les notifications',
                  subtitle: 'Envoyer une notification de test',
                  icon: Icons.send_rounded,
                  onTap: _sendTestNotification,
                ),
                _buildActionTile(
                  title: 'Voir les notifications programmées',
                  subtitle: 'Afficher toutes les notifications en attente',
                  icon: Icons.schedule_send_rounded,
                  onTap: _showPendingNotifications,
                ),
                _buildActionTile(
                  title: 'Annuler toutes les notifications',
                  subtitle: 'Supprimer toutes les notifications programmées',
                  icon: Icons.clear_all_rounded,
                  onTap: _cancelAllNotifications,
                  isDestructive: true,
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

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: colorScheme.onSurfaceVariant,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall,
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
          Switch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double>? onChanged,
    required String valueLabel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    valueLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
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
                          color: color,
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

  Future<void> _sendTestNotification() async {
    await AdvancedNotificationService.showInstantNotification(
      title: 'Notification de test',
      body: 'Ceci est une notification de test de Rentilax Tracker',
      type: NotificationType.info,
    );

    if (mounted) {
      EnhancedSnackBar.showSuccess(
        context: context,
        message: 'Notification de test envoyée',
      );
    }
  }

  Future<void> _showPendingNotifications() async {
    final pendingNotifications =
        await AdvancedNotificationService.getPendingNotifications();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications programmées'),
        content: SizedBox(
          width: double.maxFinite,
          child: pendingNotifications.isEmpty
              ? const Text('Aucune notification programmée')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: pendingNotifications.length,
                  itemBuilder: (context, index) {
                    final notification = pendingNotifications[index];
                    return ListTile(
                      title: Text(notification.title ?? 'Sans titre'),
                      subtitle: Text(notification.body ?? 'Sans contenu'),
                      trailing: Text('ID: ${notification.id}'),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAllNotifications() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text(
            'Êtes-vous sûr de vouloir annuler toutes les notifications programmées ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AdvancedNotificationService.cancelAllNotifications();

      if (mounted) {
        EnhancedSnackBar.showSuccess(
          context: context,
          message: 'Toutes les notifications ont été annulées',
        );
      }
    }
  }
}
