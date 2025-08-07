import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/releve.dart';
import '../services/database_service.dart';
import '../services/analytics_service.dart';

class EnhancedNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static final DatabaseService _databaseService = DatabaseService();

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Gérer le tap sur la notification
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// Programme un rappel de paiement
  static Future<void> schedulePaymentReminder(Releve releve) async {
    final locataire =
        await _databaseService.getLocataireById(releve.locataireId);
    if (locataire == null) return;

    final scheduledDate = _calculateReminderDate(releve);

    await _notifications.zonedSchedule(
      releve.id! + 1000, // ID unique pour les rappels de paiement
      '💰 Rappel de Paiement',
      'Paiement en attente pour ${locataire.nomComplet} - ${releve.montant.toStringAsFixed(0)} FCFA',
      scheduledDate,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_reminders',
          'Rappels de Paiement',
          channelDescription: 'Notifications pour les paiements en attente',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.orange,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'payment_reminder',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'payment_${releve.id}',
    );
  }

  /// Programme un rappel urgent pour paiement en retard
  static Future<void> scheduleUrgentPaymentReminder(Releve releve) async {
    final locataire =
        await _databaseService.getLocataireById(releve.locataireId);
    if (locataire == null) return;

    final daysSinceOverdue =
        DateTime.now().difference(releve.moisReleve).inDays;

    await _notifications.show(
      releve.id! + 2000, // ID unique pour les rappels urgents
      '🚨 PAIEMENT URGENT',
      '${locataire.nomComplet} - Retard de $daysSinceOverdue jours - ${releve.montant.toStringAsFixed(0)} FCFA',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'urgent_payments',
          'Paiements Urgents',
          channelDescription:
              'Notifications urgentes pour les paiements en retard',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Colors.red,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'urgent_payment',
          sound: 'default',
        ),
      ),
      payload: 'urgent_payment_${releve.id}',
    );
  }

  /// Notifie une consommation anormale
  static Future<void> notifyAnomalousConsumption(
      ConsumptionAnomaly anomaly) async {
    final severityEmoji = _getSeverityEmoji(anomaly.severity);
    final severityText = _getSeverityText(anomaly.severity);

    await _notifications.show(
      anomaly.releve.id! + 3000, // ID unique pour les anomalies
      '$severityEmoji Consommation $severityText',
      '${anomaly.locataire.nomComplet} - ${anomaly.currentConsumption.toStringAsFixed(1)} unités (moyenne: ${anomaly.averageConsumption.toStringAsFixed(1)})',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'consumption_anomalies',
          'Anomalies de Consommation',
          channelDescription: 'Notifications pour les consommations anormales',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: Colors.amber,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'consumption_anomaly',
        ),
      ),
      payload: 'anomaly_${anomaly.releve.id}',
    );
  }

  /// Programme des rappels automatiques pour tous les paiements en retard
  static Future<void> scheduleAutomaticReminders() async {
    final overdueReleves = await _databaseService.getOverdueReleves();

    for (final releve in overdueReleves) {
      final daysSinceOverdue =
          DateTime.now().difference(releve.moisReleve).inDays;

      if (daysSinceOverdue >= 7 && daysSinceOverdue < 14) {
        // Rappel normal après 7 jours
        await schedulePaymentReminder(releve);
      } else if (daysSinceOverdue >= 14) {
        // Rappel urgent après 14 jours
        await scheduleUrgentPaymentReminder(releve);
      }
    }
  }

  /// Notifie les statistiques mensuelles
  static Future<void> notifyMonthlyStats() async {
    final now = DateTime.now();
    final releves =
        await _databaseService.getRelevesForMonth(now.month, now.year);

    if (releves.isEmpty) return;

    final totalAmount = releves.fold(0.0, (sum, r) => sum + r.montant);
    final paidAmount =
        releves.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.montant);
    final collectionRate = (paidAmount / totalAmount * 100).round();

    await _notifications.show(
      9999, // ID fixe pour les stats mensuelles
      '📊 Rapport Mensuel',
      '${releves.length} relevés - ${totalAmount.toStringAsFixed(0)} FCFA - Recouvrement: $collectionRate%',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'monthly_stats',
          'Statistiques Mensuelles',
          channelDescription: 'Rapport mensuel des activités',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          color: Colors.blue,
        ),
        iOS: DarwinNotificationDetails(
          categoryIdentifier: 'monthly_stats',
        ),
      ),
      payload: 'monthly_stats',
    );
  }

  /// Annule toutes les notifications programmées
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Annule les notifications pour un relevé spécifique
  static Future<void> cancelNotificationsForReleve(int releveId) async {
    await _notifications.cancel(releveId + 1000); // Rappel normal
    await _notifications.cancel(releveId + 2000); // Rappel urgent
    await _notifications.cancel(releveId + 3000); // Anomalie
  }

  static tz.TZDateTime _calculateReminderDate(Releve releve) {
    // Programme le rappel 7 jours après la date du relevé
    final reminderDate = releve.moisReleve.add(const Duration(days: 7));
    return tz.TZDateTime.from(reminderDate, tz.local);
  }

  static String _getSeverityEmoji(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high:
        return '🔴';
      case AnomalySeverity.medium:
        return '🟡';
      case AnomalySeverity.low:
        return '🟢';
    }
  }

  static String _getSeverityText(AnomalySeverity severity) {
    switch (severity) {
      case AnomalySeverity.high:
        return 'Critique';
      case AnomalySeverity.medium:
        return 'Modérée';
      case AnomalySeverity.low:
        return 'Légère';
    }
  }
}
