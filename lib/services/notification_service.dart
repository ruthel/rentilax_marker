import 'package:flutter/material.dart';
import '../models/locataire.dart';
import '../models/releve.dart';
import '../models/cite.dart';
import 'database_service.dart';

class NotificationService {
  static final DatabaseService _databaseService = DatabaseService();

  /// Envoie un rappel de paiement par SMS (simulation)
  static Future<bool> sendPaymentReminder(
      Locataire locataire, Releve releve) async {
    try {
      if (locataire.telephone == null || locataire.telephone!.isEmpty) {
        return false;
      }

      final cite = await _databaseService.getCiteById(locataire.citeId);
      final message = _buildReminderMessage(locataire, releve, cite);

      // Simulation d'envoi SMS - dans une vraie app, utiliser un service SMS
      debugPrint('SMS envoyé à ${locataire.telephone}: $message');

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

    if (locataire.telephone != null && locataire.telephone!.isNotEmpty) {
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
}
