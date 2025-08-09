import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_drive_service.dart';

/// Service de planification pour la synchronisation automatique
class SyncSchedulerService {
  static Timer? _syncTimer;
  static bool _isInitialized = false;

  /// Initialiser le service de planification
  static Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    await _startAutoSyncIfEnabled();
  }

  /// Démarrer la synchronisation automatique si elle est activée
  static Future<void> _startAutoSyncIfEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;

      if (autoSyncEnabled) {
        final intervalHours = prefs.getInt('sync_interval_hours') ?? 24;
        await startAutoSync(intervalHours);
      }
    } catch (e) {
      debugPrint('Erreur lors du démarrage de la sync auto: $e');
    }
  }

  /// Démarrer la synchronisation automatique
  static Future<void> startAutoSync(int intervalHours) async {
    stopAutoSync(); // Arrêter le timer existant s'il y en a un

    final duration = Duration(hours: intervalHours);

    _syncTimer = Timer.periodic(duration, (timer) async {
      await _performScheduledSync();
    });

    debugPrint(
        'Synchronisation automatique démarrée (intervalle: ${intervalHours}h)');
  }

  /// Arrêter la synchronisation automatique
  static void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    debugPrint('Synchronisation automatique arrêtée');
  }

  /// Effectuer une synchronisation planifiée
  static Future<void> _performScheduledSync() async {
    try {
      debugPrint('Début de la synchronisation automatique...');

      // Vérifier si l'utilisateur est connecté à Google Drive
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        debugPrint(
            'Utilisateur non connecté à Google Drive, synchronisation annulée');
        return;
      }

      // Vérifier les conditions de synchronisation (Wi-Fi, etc.)
      if (!await _shouldPerformSync()) {
        debugPrint('Conditions de synchronisation non remplies');
        return;
      }

      // Effectuer la synchronisation
      final result = await GoogleDriveService.performAutoSync();

      if (result.success) {
        debugPrint('Synchronisation automatique réussie');
        await _updateLastSyncTime();
      } else {
        debugPrint('Synchronisation automatique échouée: ${result.message}');
      }
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation automatique: $e');
    }
  }

  /// Vérifier si la synchronisation doit être effectuée
  static Future<bool> _shouldPerformSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Vérifier si la synchronisation Wi-Fi uniquement est activée
      final wifiOnly = prefs.getBool('sync_wifi_only') ?? true;
      if (wifiOnly) {
        // TODO: Vérifier la connexion Wi-Fi
        // Pour l'instant, on assume que c'est OK
      }

      // Vérifier le délai minimum entre les synchronisations
      final lastSyncTime = prefs.getInt('last_auto_sync_time') ?? 0;
      final now = DateTime.now().millisecondsSinceEpoch;
      final minInterval = Duration(hours: 1).inMilliseconds; // Minimum 1 heure

      if (now - lastSyncTime < minInterval) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des conditions: $e');
      return false;
    }
  }

  /// Mettre à jour l'heure de la dernière synchronisation
  static Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_auto_sync_time', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Erreur lors de la mise à jour du timestamp: $e');
    }
  }

  /// Configurer la synchronisation automatique
  static Future<void> configureAutoSync({
    required bool enabled,
    required int intervalHours,
    bool? wifiOnly,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Sauvegarder les paramètres
      await prefs.setBool('auto_sync_enabled', enabled);
      await prefs.setInt('sync_interval_hours', intervalHours);
      if (wifiOnly != null) {
        await prefs.setBool('sync_wifi_only', wifiOnly);
      }

      // Redémarrer la synchronisation avec les nouveaux paramètres
      if (enabled) {
        await startAutoSync(intervalHours);
      } else {
        stopAutoSync();
      }

      // Configurer aussi le service Google Drive
      await GoogleDriveService.configureAutoSync(
        enabled: enabled,
        intervalHours: intervalHours,
        wifiOnly: wifiOnly,
      );

      debugPrint(
          'Configuration de la sync auto mise à jour: enabled=$enabled, interval=${intervalHours}h');
    } catch (e) {
      debugPrint('Erreur lors de la configuration: $e');
    }
  }

  /// Forcer une synchronisation immédiate
  static Future<SyncResult> forceSyncNow() async {
    try {
      debugPrint('Synchronisation forcée demandée...');

      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        return SyncResult(
          success: false,
          message: 'Utilisateur non connecté à Google Drive',
        );
      }

      final result = await GoogleDriveService.performAutoSync();

      if (result.success) {
        await _updateLastSyncTime();
      }

      return result;
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Erreur lors de la synchronisation: $e',
      );
    }
  }

  /// Obtenir le statut de la synchronisation automatique
  static Future<AutoSyncStatus> getAutoSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final enabled = prefs.getBool('auto_sync_enabled') ?? false;
      final intervalHours = prefs.getInt('sync_interval_hours') ?? 24;
      final wifiOnly = prefs.getBool('sync_wifi_only') ?? true;
      final lastSyncTime = prefs.getInt('last_auto_sync_time') ?? 0;
      final lastManualSyncTime = prefs.getInt('last_sync_time') ?? 0;

      final lastSync = lastSyncTime > lastManualSyncTime
          ? DateTime.fromMillisecondsSinceEpoch(lastSyncTime)
          : DateTime.fromMillisecondsSinceEpoch(lastManualSyncTime);

      final nextSync =
          enabled ? lastSync.add(Duration(hours: intervalHours)) : null;

      return AutoSyncStatus(
        enabled: enabled,
        intervalHours: intervalHours,
        wifiOnly: wifiOnly,
        lastSyncTime: lastSyncTime > 0 ? lastSync : null,
        nextSyncTime: nextSync,
        isRunning: _syncTimer?.isActive ?? false,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération du statut: $e');
      return AutoSyncStatus(
        enabled: false,
        intervalHours: 24,
        wifiOnly: true,
        lastSyncTime: null,
        nextSyncTime: null,
        isRunning: false,
      );
    }
  }

  /// Nettoyer les ressources
  static void dispose() {
    stopAutoSync();
    _isInitialized = false;
  }
}

/// Statut de la synchronisation automatique
class AutoSyncStatus {
  final bool enabled;
  final int intervalHours;
  final bool wifiOnly;
  final DateTime? lastSyncTime;
  final DateTime? nextSyncTime;
  final bool isRunning;

  AutoSyncStatus({
    required this.enabled,
    required this.intervalHours,
    required this.wifiOnly,
    this.lastSyncTime,
    this.nextSyncTime,
    required this.isRunning,
  });

  String get intervalDescription {
    switch (intervalHours) {
      case 1:
        return 'Toutes les heures';
      case 6:
        return 'Toutes les 6 heures';
      case 12:
        return 'Toutes les 12 heures';
      case 24:
        return 'Quotidienne';
      case 168:
        return 'Hebdomadaire';
      default:
        return 'Toutes les $intervalHours heures';
    }
  }

  String? get nextSyncDescription {
    if (nextSyncTime == null) return null;

    final now = DateTime.now();
    final difference = nextSyncTime!.difference(now);

    if (difference.isNegative) {
      return 'En attente';
    }

    if (difference.inDays > 0) {
      return 'Dans ${difference.inDays} jour(s)';
    } else if (difference.inHours > 0) {
      return 'Dans ${difference.inHours} heure(s)';
    } else if (difference.inMinutes > 0) {
      return 'Dans ${difference.inMinutes} minute(s)';
    } else {
      return 'Bientôt';
    }
  }
}
