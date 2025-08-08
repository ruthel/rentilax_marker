import 'package:flutter/material.dart';
import '../models/locataire.dart';
import '../models/releve.dart';
import '../models/cite.dart';
import 'database_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final DatabaseService _databaseService = DatabaseService();
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initializationSettings);
  }

  /// Envoie un rappel de paiement par SMS (simulation)
  static Future<bool> sendPaymentReminder(
      Locataire locataire, Releve releve) async {
    try {
      if (locataire.contact == null || locataire.contact!.isEmpty) {
        return false;
      }

      final cite = await _databaseService.getCiteById(locataire.citeId);
      final message = _buildReminderMessage(locataire, releve, cite);

      // Simulation d'envoi SMS - dans une vraie app, utiliser un service SMS
      debugPrint('SMS envoyé à ${locataire.contact}: $message');

      // Enregistrer la notification dans la base
      await _databaseService.insertNotification(
        locataireId: locataire.id!,
        type: 'payment_reminder',
        message: message,
        sentAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      debugPrint('Erreur envoi SMS: $e');
      return false;
    }
  }

  /// Envoie un rappel par email (simulation)
  static Future<bool> sendEmailReminder(
      Locataire locataire, Releve releve) async {
    try {
      if (locataire.email == null || locataire.email!.isEmpty) {
        return false;
      }

      final cite = await _databaseService.getCiteById(locataire.citeId);
      final subject = 'Rappel de paiement - ${cite?.nom ?? 'Votre logement'}';
      final message = _buildEmailReminderMessage(locataire, releve, cite);

      // Simulation d'envoi email
      debugPrint('Email envoyé à ${locataire.email}: $subject\n$message');

      await _databaseService.insertNotification(
        locataireId: locataire.id!,
        type: 'email_reminder',
        message: message,
        sentAt: DateTime.now(),
      );

      return true;
    } catch (e) {
      debugPrint('Erreur envoi email: $e');
      return false;
    }
  }

  /// Envoie une notification push locale
  static Future<void> sendLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Utiliser flutter_local_notifications dans une vraie app
    debugPrint('Notification: $title - $body');
  }

  /// Programme des rappels automatiques
  static Future<void> scheduleAutomaticReminders() async {
    final overdueReleves = await _databaseService.getOverdueReleves();

    for (final releve in overdueReleves) {
      final locataire =
          await _databaseService.getLocataireById(releve.locataireId);
      if (locataire != null) {
        final daysSinceOverdue =
            DateTime.now().difference(releve.moisReleve).inDays;

        // Rappel après 7 jours
        if (daysSinceOverdue >= 7 && daysSinceOverdue < 14) {
          await sendPaymentReminder(locataire, releve);
        }
        // Rappel urgent après 14 jours
        else if (daysSinceOverdue >= 14) {
          await sendUrgentReminder(locataire, releve);
        }
      }
    }
  }

  /// Envoie un rappel urgent
  static Future<bool> sendUrgentReminder(
      Locataire locataire, Releve releve) async {
    // Message d'urgence pour rappel

    // Envoyer par SMS ET email si disponibles
    bool smsResult = false;
    bool emailResult = false;

    if (locataire.contact != null && locataire.contact!.isNotEmpty) {
      smsResult = await sendPaymentReminder(locataire, releve);
    }

    if (locataire.email != null && locataire.email!.isNotEmpty) {
      emailResult = await sendEmailReminder(locataire, releve);
    }

    return smsResult || emailResult;
  }

  static String _buildReminderMessage(
      Locataire locataire, Releve releve, Cite? cite) {
    final remainingAmount = releve.montant - releve.paidAmount;
    return '''
Bonjour ${locataire.prenom},

Rappel de paiement pour votre consommation de ${cite?.nom ?? 'votre logement'}.
Montant dû: ${remainingAmount.toStringAsFixed(2)} FCFA
Période: ${releve.moisReleve.month}/${releve.moisReleve.year}

Merci de régulariser votre situation.
''';
  }

  static String _buildEmailReminderMessage(
      Locataire locataire, Releve releve, Cite? cite) {
    final remainingAmount = releve.montant - releve.paidAmount;
    return '''
Bonjour ${locataire.prenom} ${locataire.nom},

Nous vous rappelons qu'un paiement est en attente pour votre logement ${locataire.numeroLogement} à ${cite?.nom ?? 'votre résidence'}.

Détails:
- Période: ${releve.moisReleve.month}/${releve.moisReleve.year}
- Consommation: ${releve.consommation.toStringAsFixed(2)} unités
- Montant total: ${releve.montant.toStringAsFixed(2)} FCFA
- Montant déjà payé: ${releve.paidAmount.toStringAsFixed(2)} FCFA
- Montant restant: ${remainingAmount.toStringAsFixed(2)} FCFA

Merci de procéder au règlement dans les plus brefs délais.

Cordialement,
L'équipe de gestion
''';
  }

  Future<void> showTarifChangeNotification({
    required String unitName,
    required double oldTarif,
    required double newTarif,
    required String devise,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tarif_changes',
      'Changements de tarifs',
      channelDescription: 'Notifications pour les changements de tarifs',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      1,
      'Changement de tarif',
      'Le tarif de $unitName a changé de ${oldTarif.toStringAsFixed(2)} à ${newTarif.toStringAsFixed(2)} $devise',
      details,
    );
  }

  Future<void> showTarifUpdateNotification({
    required String unitName,
    required double newTarif,
    required String devise,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tarif_updates',
      'Mises à jour de tarifs',
      channelDescription: 'Notifications pour les mises à jour de tarifs',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      2,
      'Tarif mis à jour',
      'Le tarif de $unitName a été mis à jour à ${newTarif.toStringAsFixed(2)} $devise',
      details,
    );
  }

  Future<void> showTarifDeletionNotification({
    required String unitName,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'tarif_deletions',
      'Suppressions de tarifs',
      channelDescription: 'Notifications pour les suppressions de tarifs',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      3,
      'Tarif supprimé',
      'Le tarif personnalisé de $unitName a été supprimé. Le tarif de base sera utilisé.',
      details,
    );
  }

  Future<void> showBulkTarifUpdateNotification({
    required int updatedCount,
    required String type,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'bulk_tarif_updates',
      'Mises à jour en masse',
      channelDescription: 'Notifications pour les mises à jour en masse',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      4,
      'Mise à jour en masse',
      '$updatedCount tarifs de type $type ont été mis à jour',
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}
