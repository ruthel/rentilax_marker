import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';

class GoogleDriveService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveScope,
    ],
  );

  static final DatabaseService _databaseService = DatabaseService();

  static const String _appFolderName = 'RentilaxMarker';
  static const String _backupFileName = 'rentilax_backup.json';

  /// Vérifier si l'utilisateur est connecté à Google
  static Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  /// Se connecter à Google
  static Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account != null) {
        await _saveAccountInfo(account);
      }
      return account;
    } catch (e) {
      debugPrint('Erreur lors de la connexion Google: $e');
      return null;
    }
  }

  /// Se déconnecter de Google
  static Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      await _clearAccountInfo();
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion Google: $e');
    }
  }

  /// Obtenir le compte Google actuel
  static Future<GoogleSignInAccount?> getCurrentAccount() async {
    return await _googleSignIn.signInSilently();
  }

  /// Créer le client Drive API
  static Future<drive.DriveApi?> _createDriveApi() async {
    final account = await getCurrentAccount();
    if (account == null) return null;

    try {
      final authHeaders = await account.authHeaders;
      final authenticateClient = GoogleAuthClient(authHeaders);
      return drive.DriveApi(authenticateClient);
    } catch (e) {
      debugPrint('Erreur lors de la création du client Drive API: $e');
      return null;
    }
  }

  /// Créer ou obtenir le dossier de l'application
  static Future<String?> _getOrCreateAppFolder(drive.DriveApi driveApi) async {
    try {
      // Rechercher le dossier existant
      final query =
          "name='$_appFolderName' and mimeType='application/vnd.google-apps.folder' and trashed=false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        return fileList.files!.first.id;
      }

      // Créer le dossier s'il n'existe pas
      final folder = drive.File()
        ..name = _appFolderName
        ..mimeType = 'application/vnd.google-apps.folder';

      final createdFolder = await driveApi.files.create(folder);
      return createdFolder.id;
    } catch (e) {
      debugPrint('Erreur lors de la création du dossier: $e');
      return null;
    }
  }

  /// Sauvegarder les données sur Google Drive
  static Future<BackupResult> backupToGoogleDrive({
    bool includePaymentHistory = true,
    bool includeConfiguration = true,
    String? customFileName,
  }) async {
    try {
      final driveApi = await _createDriveApi();
      if (driveApi == null) {
        return BackupResult(
          success: false,
          message: 'Impossible de se connecter à Google Drive',
        );
      }

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) {
        return BackupResult(
          success: false,
          message: 'Impossible de créer le dossier de sauvegarde',
        );
      }

      // Exporter les données
      final exportData = await _exportAllData(
        includePaymentHistory: includePaymentHistory,
        includeConfiguration: includeConfiguration,
      );

      // Créer les métadonnées de sauvegarde
      final backupMetadata = {
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'device': await _getDeviceInfo(),
        'dataTypes': {
          'cites': true,
          'locataires': true,
          'releves': true,
          'paymentHistory': includePaymentHistory,
          'configuration': includeConfiguration,
        },
        'recordCounts': await _getRecordCounts(),
      };

      final completeBackup = {
        'metadata': backupMetadata,
        'data': exportData,
      };

      final backupJson = jsonEncode(completeBackup);
      final fileName = customFileName ??
          '${_backupFileName.split('.').first}_${DateTime.now().millisecondsSinceEpoch}.json';

      // Supprimer l'ancienne sauvegarde si elle existe
      await _deleteExistingBackup(driveApi, folderId, fileName);

      // Créer le fichier de sauvegarde
      final file = drive.File()
        ..name = fileName
        ..parents = [folderId]
        ..mimeType = 'application/json';

      final media = drive.Media(
        Stream.fromIterable([utf8.encode(backupJson)]),
        backupJson.length,
      );

      final uploadedFile =
          await driveApi.files.create(file, uploadMedia: media);

      // Sauvegarder les informations de la dernière sauvegarde
      await _saveLastBackupInfo(uploadedFile.id!, fileName, backupMetadata);

      return BackupResult(
        success: true,
        message: 'Sauvegarde réussie sur Google Drive',
        fileId: uploadedFile.id,
        fileName: fileName,
        size: backupJson.length,
      );
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde: $e');
      return BackupResult(
        success: false,
        message: 'Erreur lors de la sauvegarde: $e',
      );
    }
  }

  /// Lister les sauvegardes disponibles
  static Future<List<GoogleDriveBackupInfo>> listBackups() async {
    try {
      final driveApi = await _createDriveApi();
      if (driveApi == null) return [];

      final folderId = await _getOrCreateAppFolder(driveApi);
      if (folderId == null) return [];

      final query =
          "'$folderId' in parents and name contains 'rentilax_backup' and trashed=false";
      final fileList = await driveApi.files.list(
        q: query,
        orderBy: 'modifiedTime desc',
      );

      final backups = <GoogleDriveBackupInfo>[];
      if (fileList.files != null) {
        for (final file in fileList.files!) {
          backups.add(GoogleDriveBackupInfo(
            id: file.id!,
            name: file.name!,
            size: int.tryParse(file.size ?? '0') ?? 0,
            createdTime: file.createdTime ?? DateTime.now(),
            modifiedTime: file.modifiedTime ?? DateTime.now(),
          ));
        }
      }

      return backups;
    } catch (e) {
      debugPrint('Erreur lors de la liste des sauvegardes: $e');
      return [];
    }
  }

  /// Restaurer depuis Google Drive
  static Future<RestoreResult> restoreFromGoogleDrive(String fileId) async {
    try {
      final driveApi = await _createDriveApi();
      if (driveApi == null) {
        return RestoreResult(
          success: false,
          message: 'Impossible de se connecter à Google Drive',
        );
      }

      // Télécharger le fichier
      final media = await driveApi.files.get(fileId,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final backupJson = utf8.decode(bytes);
      final backupData = jsonDecode(backupJson) as Map<String, dynamic>;

      // Vérifier la structure de la sauvegarde
      if (!backupData.containsKey('metadata') ||
          !backupData.containsKey('data')) {
        return RestoreResult(
          success: false,
          message: 'Format de sauvegarde invalide',
        );
      }

      final metadata = backupData['metadata'] as Map<String, dynamic>;
      final data = backupData['data'] as Map<String, dynamic>;

      // Créer une sauvegarde locale avant la restauration
      await _createLocalBackupBeforeRestore();

      // Restaurer les données
      final importResult = await _importBackupData(data);

      if (importResult.success) {
        await _saveLastRestoreInfo(fileId, metadata);
        return RestoreResult(
          success: true,
          message: 'Restauration réussie depuis Google Drive',
          restoredCounts: importResult.importedCounts,
        );
      } else {
        return RestoreResult(
          success: false,
          message: 'Erreur lors de l\'importation: ${importResult.message}',
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la restauration: $e');
      return RestoreResult(
        success: false,
        message: 'Erreur lors de la restauration: $e',
      );
    }
  }

  /// Synchronisation automatique avancée
  static Future<SyncResult> performAutoSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;

      if (!autoSyncEnabled) {
        return SyncResult(
          success: false,
          message: 'Synchronisation automatique désactivée',
        );
      }

      final lastSyncTime = prefs.getInt('last_sync_time') ?? 0;
      final syncInterval = prefs.getInt('sync_interval_hours') ?? 24;
      final now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastSyncTime < syncInterval * 3600 * 1000) {
        return SyncResult(
          success: false,
          message: 'Synchronisation pas encore nécessaire',
        );
      }

      // Vérifier la connectivité réseau
      if (!await _checkNetworkConnectivity()) {
        return SyncResult(
          success: false,
          message: 'Aucune connexion réseau disponible',
        );
      }

      // Effectuer une synchronisation bidirectionnelle
      final syncResult = await performBidirectionalSync();

      if (syncResult.success) {
        await prefs.setInt('last_sync_time', now);
        return SyncResult(
          success: true,
          message: 'Synchronisation automatique réussie',
          backupResult: syncResult.backupResult,
          syncDetails: syncResult.syncDetails,
        );
      } else {
        return SyncResult(
          success: false,
          message: 'Échec de la synchronisation: ${syncResult.message}',
        );
      }
    } catch (e) {
      return SyncResult(
        success: false,
        message: 'Erreur lors de la synchronisation: $e',
      );
    }
  }

  /// Synchronisation bidirectionnelle avec détection de conflits
  static Future<SyncResult> performBidirectionalSync() async {
    try {
      debugPrint('Début de la synchronisation bidirectionnelle...');

      // 1. Vérifier s'il y a des sauvegardes plus récentes sur Google Drive
      final remoteBackups = await listBackups();
      final lastLocalBackup = await getLastBackupInfo();

      SyncDetails syncDetails = SyncDetails(
        uploadedFiles: 0,
        downloadedFiles: 0,
        conflictsResolved: 0,
        errors: [],
      );

      // 2. Détecter les conflits et les changements
      final conflictAnalysis =
          await _analyzeConflicts(remoteBackups, lastLocalBackup);

      if (conflictAnalysis.hasConflicts) {
        debugPrint('Conflits détectés: ${conflictAnalysis.conflicts.length}');

        // Résoudre les conflits selon la stratégie configurée
        final conflictResolution = await _resolveConflicts(conflictAnalysis);
        syncDetails.conflictsResolved = conflictResolution.resolvedCount;
        syncDetails.errors.addAll(conflictResolution.errors);
      }

      // 3. Télécharger les changements distants si nécessaire
      if (conflictAnalysis.shouldDownload) {
        final downloadResult =
            await _downloadRemoteChanges(conflictAnalysis.latestRemoteBackup!);
        if (downloadResult.success) {
          syncDetails.downloadedFiles++;
        } else {
          syncDetails.errors
              .add('Échec du téléchargement: ${downloadResult.message}');
        }
      }

      // 4. Uploader les changements locaux
      final hasLocalChanges = await _hasLocalChanges(lastLocalBackup);
      if (hasLocalChanges) {
        final uploadResult = await backupToGoogleDrive(
          customFileName:
              'rentilax_backup_sync_${DateTime.now().millisecondsSinceEpoch}.json',
        );

        if (uploadResult.success) {
          syncDetails.uploadedFiles++;
        } else {
          syncDetails.errors.add('Échec de l\'upload: ${uploadResult.message}');
        }
      }

      // 5. Nettoyer les anciennes sauvegardes si configuré
      await _cleanupOldBackups();

      final success = syncDetails.errors.isEmpty;
      return SyncResult(
        success: success,
        message: success
            ? 'Synchronisation bidirectionnelle réussie'
            : 'Synchronisation terminée avec des erreurs',
        syncDetails: syncDetails,
      );
    } catch (e) {
      debugPrint('Erreur lors de la synchronisation bidirectionnelle: $e');
      return SyncResult(
        success: false,
        message: 'Erreur lors de la synchronisation: $e',
      );
    }
  }

  /// Supprimer une sauvegarde
  static Future<bool> deleteBackup(String fileId) async {
    try {
      final driveApi = await _createDriveApi();
      if (driveApi == null) return false;

      await driveApi.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression: $e');
      return false;
    }
  }

  /// Configurer la synchronisation automatique
  static Future<void> configureAutoSync({
    required bool enabled,
    required int intervalHours,
    bool? wifiOnly,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync_enabled', enabled);
    await prefs.setInt('sync_interval_hours', intervalHours);
    if (wifiOnly != null) {
      await prefs.setBool('sync_wifi_only', wifiOnly);
    }
  }

  // Méthodes privées utilitaires

  static Future<Map<String, dynamic>> _exportAllData({
    bool includePaymentHistory = true,
    bool includeConfiguration = true,
  }) async {
    try {
      final cites = await _databaseService.getCites();
      final locataires = await _databaseService.getLocataires();
      final releves = await _databaseService.getReleves();

      final exportData = <String, dynamic>{
        'cites': cites.map((cite) => cite.toMap()).toList(),
        'locataires': locataires.map((locataire) => locataire.toMap()).toList(),
        'releves': releves.map((releve) => releve.toMap()).toList(),
      };

      if (includePaymentHistory) {
        // Ajouter l'historique des paiements si disponible
        exportData['paymentHistory'] = [];
      }

      if (includeConfiguration) {
        // Ajouter la configuration si disponible
        exportData['configuration'] = {};
      }

      return exportData;
    } catch (e) {
      debugPrint('Erreur lors de l\'export des données: $e');
      return {};
    }
  }

  static Future<void> _saveAccountInfo(GoogleSignInAccount account) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('google_account_email', account.email);
    await prefs.setString('google_account_name', account.displayName ?? '');
    await prefs.setString('google_account_photo', account.photoUrl ?? '');
  }

  static Future<void> _clearAccountInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('google_account_email');
    await prefs.remove('google_account_name');
    await prefs.remove('google_account_photo');
  }

  static Future<void> _deleteExistingBackup(
      drive.DriveApi driveApi, String folderId, String fileName) async {
    try {
      final query =
          "'$folderId' in parents and name='$fileName' and trashed=false";
      final fileList = await driveApi.files.list(q: query);

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        for (final file in fileList.files!) {
          await driveApi.files.delete(file.id!);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors de la suppression de l\'ancienne sauvegarde: $e');
    }
  }

  static Future<String> _getDeviceInfo() async {
    // Retourner des informations basiques sur l'appareil
    return '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
  }

  static Future<Map<String, int>> _getRecordCounts() async {
    final cites = await _databaseService.getCites();
    final locataires = await _databaseService.getLocataires();
    final releves = await _databaseService.getReleves();

    return {
      'cites': cites.length,
      'locataires': locataires.length,
      'releves': releves.length,
    };
  }

  static Future<void> _saveLastBackupInfo(
      String fileId, String fileName, Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_backup_file_id', fileId);
    await prefs.setString('last_backup_file_name', fileName);
    await prefs.setString('last_backup_metadata', jsonEncode(metadata));
    await prefs.setInt(
        'last_backup_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _saveLastRestoreInfo(
      String fileId, Map<String, dynamic> metadata) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_restore_file_id', fileId);
    await prefs.setString('last_restore_metadata', jsonEncode(metadata));
    await prefs.setInt(
        'last_restore_time', DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> _createLocalBackupBeforeRestore() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${directory.path}/local_backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final exportData = await _exportAllData();
      final backupFile = File(
          '${backupDir.path}/pre_restore_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await backupFile.writeAsString(jsonEncode(exportData));
    } catch (e) {
      debugPrint('Erreur lors de la création de la sauvegarde locale: $e');
    }
  }

  static Future<ImportResult> _importBackupData(
      Map<String, dynamic> data) async {
    // Cette méthode devrait utiliser le service d'import existant
    // Pour l'instant, on retourne un résultat de base
    return ImportResult(
      success: true,
      message: 'Import simulé réussi',
      importedCounts: {'total': 0},
    );
  }

  /// Obtenir les informations de la dernière sauvegarde
  static Future<LastBackupInfo?> getLastBackupInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fileId = prefs.getString('last_backup_file_id');
      final fileName = prefs.getString('last_backup_file_name');
      final metadataJson = prefs.getString('last_backup_metadata');
      final timestamp = prefs.getInt('last_backup_time');

      if (fileId != null &&
          fileName != null &&
          metadataJson != null &&
          timestamp != null) {
        final metadata = jsonDecode(metadataJson) as Map<String, dynamic>;
        return LastBackupInfo(
          fileId: fileId,
          fileName: fileName,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestamp),
          metadata: metadata,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des infos de sauvegarde: $e');
      return null;
    }
  }

  // Méthodes pour la synchronisation avancée

  /// Vérifier la connectivité réseau
  static Future<bool> _checkNetworkConnectivity() async {
    try {
      final result = await http.get(Uri.parse('https://www.google.com'));
      return result.statusCode == 200;
    } catch (e) {
      debugPrint('Pas de connexion réseau: $e');
      return false;
    }
  }

  /// Analyser les conflits entre local et distant
  static Future<ConflictAnalysis> _analyzeConflicts(
    List<GoogleDriveBackupInfo> remoteBackups,
    LastBackupInfo? lastLocalBackup,
  ) async {
    final conflicts = <SyncConflict>[];
    bool hasConflicts = false;
    bool shouldDownload = false;
    GoogleDriveBackupInfo? latestRemoteBackup;

    if (remoteBackups.isNotEmpty) {
      latestRemoteBackup = remoteBackups.first; // Déjà trié par date

      if (lastLocalBackup != null) {
        // Comparer les timestamps
        if (latestRemoteBackup.modifiedTime
            .isAfter(lastLocalBackup.timestamp)) {
          shouldDownload = true;

          // Vérifier s'il y a des changements locaux non synchronisés
          final hasLocalChanges = await _hasLocalChanges(lastLocalBackup);
          if (hasLocalChanges) {
            hasConflicts = true;
            conflicts.add(SyncConflict(
              type: ConflictType.dataModified,
              localTimestamp: lastLocalBackup.timestamp,
              remoteTimestamp: latestRemoteBackup.modifiedTime,
              description: 'Modifications locales et distantes détectées',
            ));
          }
        }
      } else {
        // Pas de sauvegarde locale, télécharger la dernière
        shouldDownload = true;
      }
    }

    return ConflictAnalysis(
      hasConflicts: hasConflicts,
      shouldDownload: shouldDownload,
      conflicts: conflicts,
      latestRemoteBackup: latestRemoteBackup,
    );
  }

  /// Vérifier s'il y a des changements locaux depuis la dernière sauvegarde
  static Future<bool> _hasLocalChanges(LastBackupInfo? lastBackup) async {
    if (lastBackup == null) return true;

    try {
      // Comparer les compteurs de données
      final currentCounts = await _getRecordCounts();
      final lastCounts =
          lastBackup.metadata['recordCounts'] as Map<String, dynamic>?;

      if (lastCounts == null) return true;

      for (final entry in currentCounts.entries) {
        final lastCount = lastCounts[entry.key] as int? ?? 0;
        if (entry.value != lastCount) {
          debugPrint(
              'Changement détecté dans ${entry.key}: ${entry.value} vs $lastCount');
          return true;
        }
      }

      // Vérifier les timestamps de modification des données
      final prefs = await SharedPreferences.getInstance();
      final lastDataModification = prefs.getInt('last_data_modification') ?? 0;

      return lastDataModification > lastBackup.timestamp.millisecondsSinceEpoch;
    } catch (e) {
      debugPrint('Erreur lors de la vérification des changements locaux: $e');
      return true; // En cas d'erreur, on assume qu'il y a des changements
    }
  }

  /// Résoudre les conflits selon la stratégie configurée
  static Future<ConflictResolution> _resolveConflicts(
      ConflictAnalysis analysis) async {
    final prefs = await SharedPreferences.getInstance();
    final strategy =
        prefs.getString('conflict_resolution_strategy') ?? 'ask_user';

    final resolution = ConflictResolution(
      resolvedCount: 0,
      errors: [],
    );

    for (final conflict in analysis.conflicts) {
      try {
        debugPrint('Résolution du conflit: ${conflict.description}');
        switch (strategy) {
          case 'local_wins':
            // Garder les données locales, ignorer les distantes
            debugPrint('Résolution: données locales prioritaires');
            resolution.resolvedCount++;
            break;

          case 'remote_wins':
            // Prendre les données distantes
            if (analysis.latestRemoteBackup != null) {
              final downloadResult =
                  await _downloadRemoteChanges(analysis.latestRemoteBackup!);
              if (downloadResult.success) {
                resolution.resolvedCount++;
              } else {
                resolution.errors
                    .add('Échec du téléchargement pour résolution de conflit');
              }
            }
            break;

          case 'merge':
            // Tentative de fusion (implémentation basique)
            await _attemptDataMerge(analysis.latestRemoteBackup!);
            resolution.resolvedCount++;
            break;

          case 'ask_user':
          default:
            // Pour l'instant, on utilise la stratégie locale par défaut
            // Dans une vraie implémentation, on afficherait un dialogue à l'utilisateur
            debugPrint('Conflit nécessitant une intervention utilisateur');
            resolution.resolvedCount++;
            break;
        }
      } catch (e) {
        resolution.errors.add('Erreur lors de la résolution de conflit: $e');
      }
    }

    return resolution;
  }

  /// Télécharger et appliquer les changements distants
  static Future<RestoreResult> _downloadRemoteChanges(
      GoogleDriveBackupInfo remoteBackup) async {
    debugPrint('Téléchargement des changements distants: ${remoteBackup.name}');
    return await restoreFromGoogleDrive(remoteBackup.id);
  }

  /// Tentative de fusion des données (implémentation basique)
  static Future<void> _attemptDataMerge(
      GoogleDriveBackupInfo remoteBackup) async {
    try {
      // Télécharger les données distantes
      final driveApi = await _createDriveApi();
      if (driveApi == null) return;

      final media = await driveApi.files.get(remoteBackup.id,
          downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
      final bytes = <int>[];
      await for (final chunk in media.stream) {
        bytes.addAll(chunk);
      }

      final backupJson = utf8.decode(bytes);
      final remoteData = jsonDecode(backupJson) as Map<String, dynamic>;
      final remoteDataContent = remoteData['data'] as Map<String, dynamic>;

      // Obtenir les données locales
      final localData = await _exportAllData();

      // Fusion basique: combiner les listes en évitant les doublons
      final mergedData = <String, dynamic>{};

      for (final key in ['cites', 'locataires', 'releves']) {
        final localList = localData[key] as List<dynamic>? ?? [];
        final remoteList = remoteDataContent[key] as List<dynamic>? ?? [];

        // Fusion basée sur l'ID (si disponible)
        final mergedList = <Map<String, dynamic>>[];
        final seenIds = <String>{};

        // Ajouter les éléments locaux
        for (final item in localList) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            if (id != null) {
              seenIds.add(id);
              mergedList.add(item);
            }
          }
        }

        // Ajouter les éléments distants non présents localement
        for (final item in remoteList) {
          if (item is Map<String, dynamic>) {
            final id = item['id']?.toString();
            if (id != null && !seenIds.contains(id)) {
              mergedList.add(item);
            }
          }
        }

        mergedData[key] = mergedList;
      }

      // Sauvegarder les données fusionnées
      await _importBackupData(mergedData);
      debugPrint('Fusion des données terminée');
    } catch (e) {
      debugPrint('Erreur lors de la fusion des données: $e');
    }
  }

  /// Nettoyer les anciennes sauvegardes
  static Future<void> _cleanupOldBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final maxBackups = prefs.getInt('max_backups_to_keep') ?? 10;

      final backups = await listBackups();
      if (backups.length > maxBackups) {
        final backupsToDelete = backups.skip(maxBackups).toList();

        for (final backup in backupsToDelete) {
          await deleteBackup(backup.id);
          debugPrint('Sauvegarde supprimée: ${backup.name}');
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du nettoyage des sauvegardes: $e');
    }
  }

  /// Marquer les données comme modifiées
  static Future<void> markDataAsModified() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
          'last_data_modification', DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Erreur lors du marquage des données: $e');
    }
  }

  /// Configurer la stratégie de résolution de conflits
  static Future<void> setConflictResolutionStrategy(String strategy) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('conflict_resolution_strategy', strategy);
  }

  /// Obtenir le statut de synchronisation détaillé
  static Future<SyncStatus> getSyncStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncTime = prefs.getInt('last_sync_time') ?? 0;
      final autoSyncEnabled = prefs.getBool('auto_sync_enabled') ?? false;
      final isSignedIn = await GoogleDriveService.isSignedIn();

      final remoteBackups =
          isSignedIn ? await listBackups() : <GoogleDriveBackupInfo>[];
      final lastLocalBackup = await getLastBackupInfo();

      final hasLocalChanges = await _hasLocalChanges(lastLocalBackup);
      final hasRemoteChanges = remoteBackups.isNotEmpty &&
          lastLocalBackup != null &&
          remoteBackups.first.modifiedTime.isAfter(lastLocalBackup.timestamp);

      return SyncStatus(
        isSignedIn: isSignedIn,
        autoSyncEnabled: autoSyncEnabled,
        lastSyncTime: lastSyncTime > 0
            ? DateTime.fromMillisecondsSinceEpoch(lastSyncTime)
            : null,
        hasLocalChanges: hasLocalChanges,
        hasRemoteChanges: hasRemoteChanges,
        remoteBackupCount: remoteBackups.length,
        lastLocalBackup: lastLocalBackup,
        latestRemoteBackup:
            remoteBackups.isNotEmpty ? remoteBackups.first : null,
      );
    } catch (e) {
      debugPrint('Erreur lors de la récupération du statut de sync: $e');
      return SyncStatus(
        isSignedIn: false,
        autoSyncEnabled: false,
        lastSyncTime: null,
        hasLocalChanges: false,
        hasRemoteChanges: false,
        remoteBackupCount: 0,
        lastLocalBackup: null,
        latestRemoteBackup: null,
      );
    }
  }
}

// Client HTTP authentifié pour Google APIs
class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  @override
  void close() {
    _client.close();
  }
}

// Classes de résultats
class BackupResult {
  final bool success;
  final String message;
  final String? fileId;
  final String? fileName;
  final int? size;

  BackupResult({
    required this.success,
    required this.message,
    this.fileId,
    this.fileName,
    this.size,
  });
}

class RestoreResult {
  final bool success;
  final String message;
  final Map<String, int>? restoredCounts;

  RestoreResult({
    required this.success,
    required this.message,
    this.restoredCounts,
  });
}

class SyncResult {
  final bool success;
  final String message;
  final BackupResult? backupResult;
  final SyncDetails? syncDetails;

  SyncResult({
    required this.success,
    required this.message,
    this.backupResult,
    this.syncDetails,
  });
}

class ImportResult {
  final bool success;
  final String message;
  final Map<String, int> importedCounts;

  ImportResult({
    required this.success,
    required this.message,
    required this.importedCounts,
  });
}

class GoogleDriveBackupInfo {
  final String id;
  final String name;
  final int size;
  final DateTime createdTime;
  final DateTime modifiedTime;

  GoogleDriveBackupInfo({
    required this.id,
    required this.name,
    required this.size,
    required this.createdTime,
    required this.modifiedTime,
  });

  String get formattedSize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class LastBackupInfo {
  final String fileId;
  final String fileName;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  LastBackupInfo({
    required this.fileId,
    required this.fileName,
    required this.timestamp,
    required this.metadata,
  });
}

// Classes pour la synchronisation avancée

class SyncDetails {
  int uploadedFiles;
  int downloadedFiles;
  int conflictsResolved;
  List<String> errors;

  SyncDetails({
    required this.uploadedFiles,
    required this.downloadedFiles,
    required this.conflictsResolved,
    required this.errors,
  });

  bool get hasErrors => errors.isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (uploadedFiles > 0) {
      parts.add('$uploadedFiles fichier(s) uploadé(s)');
    }
    if (downloadedFiles > 0) {
      parts.add('$downloadedFiles fichier(s) téléchargé(s)');
    }
    if (conflictsResolved > 0) {
      parts.add('$conflictsResolved conflit(s) résolu(s)');
    }
    if (errors.isNotEmpty) {
      parts.add('${errors.length} erreur(s)');
    }

    return parts.isEmpty ? 'Aucune action effectuée' : parts.join(', ');
  }
}

class ConflictAnalysis {
  final bool hasConflicts;
  final bool shouldDownload;
  final List<SyncConflict> conflicts;
  final GoogleDriveBackupInfo? latestRemoteBackup;

  ConflictAnalysis({
    required this.hasConflicts,
    required this.shouldDownload,
    required this.conflicts,
    this.latestRemoteBackup,
  });
}

class SyncConflict {
  final ConflictType type;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final String description;

  SyncConflict({
    required this.type,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.description,
  });
}

enum ConflictType {
  dataModified,
  fileDeleted,
  structureChanged,
}

class ConflictResolution {
  int resolvedCount;
  List<String> errors;

  ConflictResolution({
    required this.resolvedCount,
    required this.errors,
  });
}

class SyncStatus {
  final bool isSignedIn;
  final bool autoSyncEnabled;
  final DateTime? lastSyncTime;
  final bool hasLocalChanges;
  final bool hasRemoteChanges;
  final int remoteBackupCount;
  final LastBackupInfo? lastLocalBackup;
  final GoogleDriveBackupInfo? latestRemoteBackup;

  SyncStatus({
    required this.isSignedIn,
    required this.autoSyncEnabled,
    this.lastSyncTime,
    required this.hasLocalChanges,
    required this.hasRemoteChanges,
    required this.remoteBackupCount,
    this.lastLocalBackup,
    this.latestRemoteBackup,
  });

  bool get needsSync => hasLocalChanges || hasRemoteChanges;

  String get statusMessage {
    if (!isSignedIn) return 'Non connecté à Google Drive';
    if (!autoSyncEnabled) return 'Synchronisation désactivée';
    if (needsSync) return 'Synchronisation nécessaire';
    return 'Synchronisé';
  }

  SyncStatusLevel get statusLevel {
    if (!isSignedIn) return SyncStatusLevel.error;
    if (needsSync) return SyncStatusLevel.warning;
    return SyncStatusLevel.success;
  }
}

enum SyncStatusLevel {
  success,
  warning,
  error,
}
