import 'package:flutter/material.dart';
import '../services/advanced_notification_service.dart';

/// Exemple d'utilisation du service de notifications avancées
class NotificationUsageExample extends StatefulWidget {
  const NotificationUsageExample({super.key});

  @override
  State<NotificationUsageExample> createState() =>
      _NotificationUsageExampleState();
}

class _NotificationUsageExampleState extends State<NotificationUsageExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test des Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tester les notifications et la navigation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Test notification instantanée
            ElevatedButton.icon(
              onPressed: () => _showInstantNotification(),
              icon: const Icon(Icons.notifications),
              label: const Text('Notification instantanée'),
            ),
            const SizedBox(height: 12),

            // Test rappel de relevé
            ElevatedButton.icon(
              onPressed: () => _scheduleReadingReminder(),
              icon: const Icon(Icons.schedule),
              label: const Text('Programmer rappel de relevé'),
            ),
            const SizedBox(height: 12),

            // Test paiement en retard
            ElevatedButton.icon(
              onPressed: () => _schedulePaymentDue(),
              icon: const Icon(Icons.payment),
              label: const Text('Programmer paiement en retard'),
            ),
            const SizedBox(height: 12),

            // Test rapport mensuel
            ElevatedButton.icon(
              onPressed: () => _scheduleMonthlyReport(),
              icon: const Icon(Icons.assessment),
              label: const Text('Programmer rapport mensuel'),
            ),
            const SizedBox(height: 20),

            const Divider(),
            const Text(
              'Tester la navigation directe',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Test navigation vers relevés
            OutlinedButton.icon(
              onPressed: () => _testNavigationToReadings(),
              icon: const Icon(Icons.assessment_outlined),
              label: const Text('Navigation → Relevés'),
            ),
            const SizedBox(height: 8),

            // Test navigation vers paiements
            OutlinedButton.icon(
              onPressed: () => _testNavigationToPayments(),
              icon: const Icon(Icons.payment_outlined),
              label: const Text('Navigation → Paiements'),
            ),
            const SizedBox(height: 8),

            // Test navigation vers dashboard
            OutlinedButton.icon(
              onPressed: () => _testNavigationToDashboard(),
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Navigation → Dashboard'),
            ),

            const Spacer(),

            // Bouton pour voir les notifications en attente
            TextButton.icon(
              onPressed: () => _showPendingNotifications(),
              icon: const Icon(Icons.list),
              label: const Text('Voir notifications en attente'),
            ),

            // Bouton pour annuler toutes les notifications
            TextButton.icon(
              onPressed: () => _cancelAllNotifications(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Annuler toutes les notifications'),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showInstantNotification() async {
    await AdvancedNotificationService.showInstantNotification(
      title: 'Test de notification',
      body: 'Ceci est une notification de test instantanée',
      type: NotificationType.info,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification instantanée envoyée')),
      );
    }
  }

  Future<void> _scheduleReadingReminder() async {
    await AdvancedNotificationService.scheduleReadingReminder(
      locataireId: 123,
      locataireName: 'Jean Dupont (Test)',
      scheduledDate: DateTime.now().add(const Duration(seconds: 10)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Rappel de relevé programmé dans 10 secondes')),
      );
    }
  }

  Future<void> _schedulePaymentDue() async {
    await AdvancedNotificationService.schedulePaymentDueNotification(
      locataireId: 456,
      locataireName: 'Marie Martin (Test)',
      amount: 15000.0,
      dueDate: DateTime.now().add(const Duration(seconds: 15)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Notification de paiement programmée dans 15 secondes')),
      );
    }
  }

  Future<void> _scheduleMonthlyReport() async {
    await AdvancedNotificationService.scheduleMonthlyReportNotification();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Rapport mensuel programmé pour le 1er du mois prochain')),
      );
    }
  }

  void _testNavigationToReadings() {
    AdvancedNotificationService.testNotificationNavigation(
        'reading_reminder', '123');
  }

  void _testNavigationToPayments() {
    AdvancedNotificationService.testNotificationNavigation(
        'payment_due', '456');
  }

  void _testNavigationToDashboard() {
    AdvancedNotificationService.testNotificationNavigation(
        'monthly_report', '12');
  }

  Future<void> _showPendingNotifications() async {
    final pending = await AdvancedNotificationService.getPendingNotifications();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Notifications en attente'),
          content: SizedBox(
            width: double.maxFinite,
            child: pending.isEmpty
                ? const Text('Aucune notification en attente')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: pending.length,
                    itemBuilder: (context, index) {
                      final notification = pending[index];
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
  }

  Future<void> _cancelAllNotifications() async {
    await AdvancedNotificationService.cancelAllNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Toutes les notifications ont été annulées')),
      );
    }
  }
}
