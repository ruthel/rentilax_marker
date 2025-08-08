import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';

class AdvancedNotificationService {
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

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Demander les permissions
    await _requestPermissions();
  }

  static Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  static void _onNotificationTapped(NotificationResponse response) {
    // Gérer les actions lors du tap sur la notification
    final payload = response.payload;
    if (payload != null) {
      // Parser le payload et naviguer vers l'écran approprié
      _handleNotificationPayload(payload);
    }
  }

  static void _handleNotificationPayload(String payload) {
    // TODO: Implémenter la navigation basée sur le payload
    final parts = payload.split('|');
    if (parts.length >= 2) {
      final type = parts[0];
      // final id = parts[1]; // Unused for now

      switch (type) {
        case 'reading_reminder':
          // Naviguer vers l'écran des relevés
          break;
        case 'payment_due':
          // Naviguer vers l'écran des paiements
          break;
        case 'monthly_report':
          // Naviguer vers le rapport mensuel
          break;
      }
    }
  }

  // Notification pour rappel de relevé
  static Future<void> scheduleReadingReminder({
    required int locataireId,
    required String locataireName,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'reading_reminders',
      'Rappels de relevés',
      channelDescription:
          'Notifications pour rappeler les relevés de consommation',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF2563EB),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      locataireId + 1000, // ID unique pour les rappels de relevés
      'Rappel de relevé',
      'Il est temps de faire le relevé pour $locataireName',
      tz.TZDateTime.from(scheduledDate, tz.local),
      notificationDetails,
      payload: 'reading_reminder|$locataireId',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // Notification pour paiement en retard
  static Future<void> schedulePaymentDueNotification({
    required int locataireId,
    required String locataireName,
    required double amount,
    required DateTime dueDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'payment_due',
      'Paiements en retard',
      channelDescription: 'Notifications pour les paiements en retard',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFEF4444),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      locataireId + 2000, // ID unique pour les paiements
      'Paiement en retard',
      '$locataireName doit ${amount.toStringAsFixed(0)} FCFA depuis le ${dueDate.day}/${dueDate.month}',
      tz.TZDateTime.from(dueDate.add(const Duration(days: 1)), tz.local),
      notificationDetails,
      payload: 'payment_due|$locataireId',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Notification de rapport mensuel
  static Future<void> scheduleMonthlyReportNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'monthly_reports',
      'Rapports mensuels',
      channelDescription: 'Notifications pour les rapports mensuels',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFF10B981),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Programmer pour le 1er de chaque mois à 9h
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1, 9, 0);

    await _notifications.zonedSchedule(
      3000, // ID unique pour les rapports mensuels
      'Rapport mensuel disponible',
      'Votre rapport mensuel est prêt à être consulté',
      tz.TZDateTime.from(nextMonth, tz.local),
      notificationDetails,
      payload: 'monthly_report|${now.month}',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
    );
  }

  // Notification immédiate
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    NotificationType type = NotificationType.info,
  }) async {
    Color color;
    switch (type) {
      case NotificationType.success:
        color = const Color(0xFF10B981);
        break;
      case NotificationType.warning:
        color = const Color(0xFFF59E0B);
        break;
      case NotificationType.error:
        color = const Color(0xFFEF4444);
        break;
      case NotificationType.info:
        color = const Color(0xFF2563EB);
        break;
    }

    final androidDetails = AndroidNotificationDetails(
      'instant_notifications',
      'Notifications instantanées',
      channelDescription: 'Notifications immédiates de l\'application',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: color,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  // Programmer des rappels automatiques pour tous les locataires
  static Future<void> scheduleAllReadingReminders() async {
    final prefs = await SharedPreferences.getInstance();
    final reminderEnabled = prefs.getBool('reading_reminders_enabled') ?? true;

    if (!reminderEnabled) return;

    final reminderDay =
        prefs.getInt('reminder_day') ?? 25; // 25e jour du mois par défaut
    final reminderHour = prefs.getInt('reminder_hour') ?? 9; // 9h par défaut

    final locataires = await _databaseService.getLocataires();

    for (final locataire in locataires) {
      // Calculer la prochaine date de rappel
      final now = DateTime.now();
      DateTime nextReminder;

      if (now.day <= reminderDay) {
        // Ce mois-ci
        nextReminder = DateTime(now.year, now.month, reminderDay, reminderHour);
      } else {
        // Le mois prochain
        nextReminder =
            DateTime(now.year, now.month + 1, reminderDay, reminderHour);
      }

      await scheduleReadingReminder(
        locataireId: locataire.id!,
        locataireName: '${locataire.prenom} ${locataire.nom}',
        scheduledDate: nextReminder,
      );
    }
  }

  // Vérifier les paiements en retard et programmer des notifications
  static Future<void> checkOverduePayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentRemindersEnabled =
        prefs.getBool('payment_reminders_enabled') ?? true;

    if (!paymentRemindersEnabled) return;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Récupérer tous les relevés du mois précédent non payés
    final releves = await _databaseService.getRelevesForMonth(
      currentMonth == 1 ? 12 : currentMonth - 1,
      currentMonth == 1 ? currentYear - 1 : currentYear,
    );

    final overdueReleves = releves.where((releve) => !releve.isPaid).toList();

    for (final releve in overdueReleves) {
      final locataire =
          await _databaseService.getLocataireById(releve.locataireId);
      if (locataire != null) {
        await schedulePaymentDueNotification(
          locataireId: locataire.id!,
          locataireName: '${locataire.prenom} ${locataire.nom}',
          amount: releve.montant,
          dueDate: releve.dateReleve,
        );
      }
    }
  }

  // Annuler toutes les notifications d'un type
  static Future<void> cancelNotificationsByType(String type) async {
    final pendingNotifications =
        await _notifications.pendingNotificationRequests();

    for (final notification in pendingNotifications) {
      if (notification.payload?.startsWith(type) == true) {
        await _notifications.cancel(notification.id);
      }
    }
  }

  // Annuler toutes les notifications
  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Obtenir les notifications en attente
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  // Configurer les préférences de notification
  static Future<void> updateNotificationSettings({
    bool? readingReminders,
    bool? paymentReminders,
    bool? monthlyReports,
    int? reminderDay,
    int? reminderHour,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (readingReminders != null) {
      await prefs.setBool('reading_reminders_enabled', readingReminders);
    }

    if (paymentReminders != null) {
      await prefs.setBool('payment_reminders_enabled', paymentReminders);
    }

    if (monthlyReports != null) {
      await prefs.setBool('monthly_reports_enabled', monthlyReports);
    }

    if (reminderDay != null) {
      await prefs.setInt('reminder_day', reminderDay);
    }

    if (reminderHour != null) {
      await prefs.setInt('reminder_hour', reminderHour);
    }

    // Reprogrammer les notifications avec les nouveaux paramètres
    await cancelAllNotifications();
    await scheduleAllReadingReminders();
    await checkOverduePayments();
    await scheduleMonthlyReportNotification();
  }
}

enum NotificationType {
  success,
  warning,
  error,
  info,
}
