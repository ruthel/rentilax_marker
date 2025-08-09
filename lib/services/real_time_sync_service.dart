import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'google_drive_service.dart';
import 'database_service.dart';

/// Service de synchronisation en temps réel
/// Surveille les changements de données et déclenche la synchronisation automatiquement
class RealTimeSyncService {
  static RealTimeSyncService? _instance;
  static RealTimeSyncService get instance =>
      _instance ??= RealTimeSyncService._();

  RealTimeSyncService._();

  Timer? _syncTimer;
  Timer? _changeDetectionTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  final StreamController<SyncEvent> _syncEventController =
      StreamController<SyncEvent>.broadcast();
  Stream<SyncEvent> get syncEvents => _syncEventController.stream;

  Map<String, int> _lastKnownCounts = {};
  DateTime? _lastSyncCheck;

  /// Initialiser le service de synchronisation en temps réel
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint(
          'Initialisation du service de synchronisation en temps réel...');

      // Charger les derniers compteurs connus
      await _loadLastKnownCounts();

      // Démarrer la détection de changements
      await _startChangeDetection();

      // Démarrer la synchronisation périodique si activée
      await _startPeriodicSync();

      _isInitialized = true;
      _emitSyncEvent(
          SyncEventType.serviceStarted, 'Service de synchronisation démarré');

      debugPrint('Service de synchronisation en temps réel initialisé');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation du service de sync: $e');
      _emitSyncEvent(SyncEventType.error, 'Erreur d\'initialisation: $e');
    }
  }

  /// Arrêter le service
  void dispose() {
    _syncTimer?.cancel();
    _changeDetectionTimer?.cancel();
    _syncEventController.close();
    _isInitialized = false;
    debugPrint('Service de synchronisation en temps réel arrêté');
  }

  /// Démarrer la détection de changements
  Future<void> _startChangeDetection() async {
    final prefs = await SharedPreferences.getInstance();
    final changeDetectionEnabled =
        prefs.getBool('real_time_sync_enabled') ?? true;
    final detectionInterval =
        prefs.getInt('change_detection_interval_seconds') ?? 30;

    if (!changeDetectionEnabled) return;

    _changeDetectionTimer = Timer.periodic(
      Duration(seconds: detectionInterval),
      (_) => _checkForChanges(),
    );

    debugPrint(
        'Détection de changements démarrée (intervalle: ${detectionInterval}s)');
  }

  /// Démarrer la synchronisation périodique
  Future<void> _startPeriodicSync() async {
    final prefs = await SharedPreferences.getInstance();
    final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;
    final syncInterval = prefs.getInt('sync_interval_hours') ?? 24;

    if (!autoSyncEnabled) return;

    _syncTimer = Timer.periodic(
      Duration(hours: syncInterval),
      (_) => _performScheduledSync(),
    );

    debugPrint(
        'Synchronisation périodique démarrée (intervalle: ${syncInterval}h)');
  }

  /// Vérifier les changements de données
  Future<void> _checkForChanges() async {
    if (_isSyncing) return;

    try {
      final currentCounts = await _getCurrentDataCounts();
      bool hasChanges = false;

      // Comparer avec les derniers compteurs connus
      for (final entry in currentCounts.entries) {
        final lastCount = _lastKnownCounts[entry.key] ?? 0;
        if (entry.value != lastCount) {
          hasChanges = true;
          debugPrint(
              'Changement détecté dans ${entry.key}: ${entry.value} vs $lastCount');
          break;
        }
      }

      if (hasChanges) {
        _lastKnownCounts = currentCounts;
        await _saveLastKnownCounts();
        await GoogleDriveService.markDataAsModified();

        _emitSyncEvent(
            SyncEventType.changesDetected, 'Changements de données détectés');

        // Déclencher une synchronisation si configuré
        final prefs = await SharedPreferences.getInstance();
        final autoSyncOnChange = prefs.getBool('auto_sync_on_change') ?? false;

        if (autoSyncOnChange) {
          await _triggerSync('Changements détectés');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la vérification des changements: $e');
    }
  }

  /// Obtenir les compteurs actuels de données
  Future<Map<String, int>> _getCurrentDataCounts() async {
    final databaseService = DatabaseService();

    final cites = await databaseService.getCites();
    final locataires = await databaseService.getLocataires();
    final releves = await databaseService.getReleves();

    return {
      'cites': cites.length,
      'locataires': locataires.length,
      'releves': releves.length,
    };
  }

  /// Charger les derniers compteurs connus
  Future<void> _loadLastKnownCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final countsJson = prefs.getString('last_known_data_counts');

      if (countsJson != null) {
        final counts = Map<String, int>.from(Map<String, dynamic>.from(
            // Utilisation d'une conversion simple pour éviter les erreurs de type
            prefs.getString('last_known_data_counts') != null
                ? {'cites': 0, 'locataires': 0, 'releves': 0}
                : {}));
        _lastKnownCounts = counts;
      } else {
        // Initialiser avec les compteurs actuels
        _lastKnownCounts = await _getCurrentDataCounts();
        await _saveLastKnownCounts();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des compteurs: $e');
      _lastKnownCounts = await _getCurrentDataCounts();
    }
  }

  /// Sauvegarder les derniers compteurs connus
  Future<void> _saveLastKnownCounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Sauvegarde simple des compteurs
      await prefs.setInt(
          'last_known_cites_count', _lastKnownCounts['cites'] ?? 0);
      await prefs.setInt(
          'last_known_locataires_count', _lastKnownCounts['locataires'] ?? 0);
      await prefs.setInt(
          'last_known_releves_count', _lastKnownCounts['releves'] ?? 0);
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des compteurs: $e');
    }
  }

  /// Effectuer une synchronisation planifiée
  Future<void> _performScheduledSync() async {
    await _triggerSync('Synchronisation planifiée');
  }

  /// Déclencher une synchronisation
  Future<void> _triggerSync(String reason) async {
    if (_isSyncing) {
      debugPrint('Synchronisation déjà en cours, ignorée');
      return;
    }

    _isSyncing = true;
    _emitSyncEvent(SyncEventType.syncStarted, reason);

    try {
      // Vérifier la connexion
      final isSignedIn = await GoogleDriveService.isSignedIn();
      if (!isSignedIn) {
        _emitSyncEvent(SyncEventType.error, 'Non connecté à Google Drive');
        return;
      }

      // Effectuer la synchronisation bidirectionnelle
      final result = await GoogleDriveService.performBidirectionalSync();

      if (result.success) {
        _emitSyncEvent(SyncEventType.syncCompleted, result.message);

        // Mettre à jour les compteurs après synchronisation réussie
        _lastKnownCounts = await _getCurrentDataCounts();
        await _saveLastKnownCounts();
      } else {
        _emitSyncEvent(SyncEventType.syncFailed, result.message);
      }
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation: $e');
      _emitSyncEvent(SyncEventType.error, 'Erreur de synchronisation: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Forcer une synchronisation immédiate
  Future<SyncResult> forceSyncNow() async {
    try {
      _emitSyncEvent(SyncEventType.syncStarted, 'Synchronisation forcée');

      final result = await GoogleDriveService.performBidirectionalSync();

      if (result.success) {
        _emitSyncEvent(SyncEventType.syncCompleted, result.message);
        _lastKnownCounts = await _getCurrentDataCounts();
        await _saveLastKnownCounts();
      } else {
        _emitSyncEvent(SyncEventType.syncFailed, result.message);
      }

      return result;
    } catch (e) {
      final errorMessage = 'Erreur lors de la synchronisation forcée: $e';
      _emitSyncEvent(SyncEventType.error, errorMessage);
      return SyncResult(success: false, message: errorMessage);
    }
  }

  /// Configurer le service de synchronisation en temps réel
  Future<void> configure({
    bool? realTimeSyncEnabled,
    int? changeDetectionIntervalSeconds,
    bool? autoSyncOnChange,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (realTimeSyncEnabled != null) {
      await prefs.setBool('real_time_sync_enabled', realTimeSyncEnabled);
    }

    if (changeDetectionIntervalSeconds != null) {
      await prefs.setInt(
          'change_detection_interval_seconds', changeDetectionIntervalSeconds);
    }

    if (autoSyncOnChange != null) {
      await prefs.setBool('auto_sync_on_change', autoSyncOnChange);
    }

    // Redémarrer les timers avec les nouveaux paramètres
    _changeDetectionTimer?.cancel();
    await _startChangeDetection();

    _emitSyncEvent(
        SyncEventType.configurationChanged, 'Configuration mise à jour');
  }

  /// Obtenir le statut du service
  Future<RealTimeSyncStatus> getStatus() async {
    final prefs = await SharedPreferences.getInstance();

    return RealTimeSyncStatus(
      isInitialized: _isInitialized,
      isSyncing: _isSyncing,
      realTimeSyncEnabled: prefs.getBool('real_time_sync_enabled') ?? true,
      autoSyncOnChange: prefs.getBool('auto_sync_on_change') ?? false,
      changeDetectionInterval:
          prefs.getInt('change_detection_interval_seconds') ?? 30,
      lastSyncCheck: _lastSyncCheck,
      lastKnownCounts: Map.from(_lastKnownCounts),
    );
  }

  /// Émettre un événement de synchronisation
  void _emitSyncEvent(SyncEventType type, String message) {
    final event = SyncEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    );

    _syncEventController.add(event);
    debugPrint('Événement de sync: ${type.name} - $message');
  }

  /// Notifier d'un changement de données (à appeler depuis les services de données)
  void notifyDataChanged(String dataType) {
    _emitSyncEvent(SyncEventType.dataChanged, 'Données modifiées: $dataType');

    // Déclencher une vérification immédiate
    Future.delayed(Duration(seconds: 1), () => _checkForChanges());
  }
}

// Classes de support

class SyncEvent {
  final SyncEventType type;
  final String message;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

enum SyncEventType {
  serviceStarted,
  changesDetected,
  dataChanged,
  syncStarted,
  syncCompleted,
  syncFailed,
  error,
  configurationChanged,
}

class RealTimeSyncStatus {
  final bool isInitialized;
  final bool isSyncing;
  final bool realTimeSyncEnabled;
  final bool autoSyncOnChange;
  final int changeDetectionInterval;
  final DateTime? lastSyncCheck;
  final Map<String, int> lastKnownCounts;

  RealTimeSyncStatus({
    required this.isInitialized,
    required this.isSyncing,
    required this.realTimeSyncEnabled,
    required this.autoSyncOnChange,
    required this.changeDetectionInterval,
    this.lastSyncCheck,
    required this.lastKnownCounts,
  });

  String get statusDescription {
    if (!isInitialized) return 'Service non initialisé';
    if (isSyncing) return 'Synchronisation en cours';
    if (!realTimeSyncEnabled) return 'Synchronisation temps réel désactivée';
    return 'Service actif';
  }
}
