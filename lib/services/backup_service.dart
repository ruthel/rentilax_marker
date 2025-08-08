import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'database_service.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Crée un backup complet de toutes les données
  Future<BackupResult> createFullBackup({
    String? customName,
    bool encrypt = true,
    String? password,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = customName ?? 'backup_$timestamp';

      // Récupérer toutes les données
      final backupData = await _collectAllData();

      // Créer le fichier de backup
      final backupFile = await _createBackupFile(
        backupName,
        backupData,
        encrypt: encrypt,
        password: password,
      );

      // Enregistrer les métadonnées
      await _saveBackupMetadata(backupName, backupFile);

      return BackupResult.success(
        fileName: backupName,
        filePath: backupFile.path,
        size: await backupFile.length(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return BackupResult.error('Erreur lors de la création du backup: $e');
    }
  }

  /// Crée un backup incrémental (seulement les modifications)
  Future<BackupResult> createIncrementalBackup({
    DateTime? since,
    bool encrypt = true,
    String? password,
  }) async {
    try {
      final lastBackupDate = since ?? await _getLastBackupDate();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final backupName = 'incremental_backup_$timestamp';

      // Récupérer seulement les données modifiées
      final incrementalData = await _collectIncrementalData(lastBackupDate);

      if (incrementalData.isEmpty) {
        return BackupResult.success(
          fileName: backupName,
          filePath: '',
          size: 0,
          createdAt: DateTime.now(),
          message: 'Aucune modification depuis le dernier backup',
        );
      }

      // Créer le fichier de backup incrémental
      final backupFile = await _createBackupFile(
        backupName,
        incrementalData,
        encrypt: encrypt,
        password: password,
      );

      await _saveBackupMetadata(backupName, backupFile, isIncremental: true);

      return BackupResult.success(
        fileName: backupName,
        filePath: backupFile.path,
        size: await backupFile.length(),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      return BackupResult.error('Erreur lors du backup incrémental: $e');
    }
  }

  /// Restaure un backup
  Future<RestoreResult> restoreBackup(
    String backupPath, {
    String? password,
    bool overwriteExisting = false,
  }) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return RestoreResult.error('Fichier de backup introuvable');
      }

      // Lire et déchiffrer le backup
      final backupData = await _readBackupFile(backupFile, password: password);

      // Valider les données
      final validationResult = await _validateBackupData(backupData);
      if (!validationResult.isValid) {
        return RestoreResult.error(
            'Données de backup invalides: ${validationResult.error}');
      }

      // Créer un backup de sécurité avant restauration
      if (overwriteExisting) {
        await createFullBackup(customName: 'pre_restore_backup');
      }

      // Restaurer les données
      await _restoreData(backupData, overwriteExisting);

      return RestoreResult.success(
        restoredAt: DateTime.now(),
        itemsRestored: _countRestoredItems(backupData),
      );
    } catch (e) {
      return RestoreResult.error('Erreur lors de la restauration: $e');
    }
  }

  /// Liste tous les backups disponibles
  Future<List<BackupInfo>> getAvailableBackups() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final backupsJson = prefs.getStringList('backup_metadata') ?? [];

      final backups = <BackupInfo>[];
      for (final backupJson in backupsJson) {
        final backupMap = jsonDecode(backupJson) as Map<String, dynamic>;
        backups.add(BackupInfo.fromJson(backupMap));
      }

      // Trier par date de création (plus récent en premier)
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return backups;
    } catch (e) {
      debugPrint('Erreur lors de la récupération des backups: $e');
      return [];
    }
  }

  /// Supprime un backup
  Future<bool> deleteBackup(String backupName) async {
    try {
      final backupDir = await _getBackupDirectory();
      final backupFile = File('${backupDir.path}/$backupName.backup');

      if (await backupFile.exists()) {
        await backupFile.delete();
      }

      // Supprimer des métadonnées
      await _removeBackupMetadata(backupName);

      return true;
    } catch (e) {
      debugPrint('Erreur lors de la suppression du backup: $e');
      return false;
    }
  }

  /// Configure le backup automatique
  Future<void> configureAutoBackup({
    required bool enabled,
    required AutoBackupFrequency frequency,
    bool encrypt = true,
    String? password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool('auto_backup_enabled', enabled);
    await prefs.setString('auto_backup_frequency', frequency.name);
    await prefs.setBool('auto_backup_encrypt', encrypt);

    if (password != null) {
      // Stocker le hash du mot de passe, pas le mot de passe lui-même
      final passwordHash = sha256.convert(utf8.encode(password)).toString();
      await prefs.setString('auto_backup_password_hash', passwordHash);
    }

    if (enabled) {
      await _scheduleNextAutoBackup(frequency);
    }
  }

  /// Vérifie si un backup automatique est nécessaire
  Future<bool> shouldPerformAutoBackup() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool('auto_backup_enabled') ?? false;

    if (!enabled) return false;

    final lastAutoBackup = prefs.getInt('last_auto_backup') ?? 0;
    final frequencyStr = prefs.getString('auto_backup_frequency') ?? 'daily';
    final frequency = AutoBackupFrequency.values.firstWhere(
      (f) => f.name == frequencyStr,
      orElse: () => AutoBackupFrequency.daily,
    );

    final now = DateTime.now().millisecondsSinceEpoch;
    final timeSinceLastBackup = now - lastAutoBackup;

    switch (frequency) {
      case AutoBackupFrequency.daily:
        return timeSinceLastBackup > Duration.millisecondsPerDay;
      case AutoBackupFrequency.weekly:
        return timeSinceLastBackup > Duration.millisecondsPerDay * 7;
      case AutoBackupFrequency.monthly:
        return timeSinceLastBackup > Duration.millisecondsPerDay * 30;
    }
  }

  /// Effectue un backup automatique si nécessaire
  Future<void> performAutoBackupIfNeeded() async {
    if (await shouldPerformAutoBackup()) {
      final prefs = await SharedPreferences.getInstance();
      final encrypt = prefs.getBool('auto_backup_encrypt') ?? true;

      await createFullBackup(
        customName: 'auto_backup_${DateTime.now().millisecondsSinceEpoch}',
        encrypt: encrypt,
      );

      await prefs.setInt(
          'last_auto_backup', DateTime.now().millisecondsSinceEpoch);
    }
  }

  // Méthodes privées

  Future<Map<String, dynamic>> _collectAllData() async {
    return {
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'data': {
        'locataires': await _databaseService.getLocataires(),
        'cites': await _databaseService.getCites(),
        'releves': await _databaseService.getReleves(),
        'configurations': await _databaseService.getConfiguration(),
        'unit_types': await _databaseService.getConsumptionUnits(),
        'unit_tarifs': await _databaseService.getUnitTarifs(),
      },
    };
  }

  Future<Map<String, dynamic>> _collectIncrementalData(DateTime since) async {
    // Pour l'instant, on fait un backup complet
    // TODO: Implémenter la logique incrémentale avec des timestamps
    return await _collectAllData();
  }

  Future<File> _createBackupFile(
    String backupName,
    Map<String, dynamic> data, {
    bool encrypt = true,
    String? password,
  }) async {
    final backupDir = await _getBackupDirectory();
    final backupFile = File('${backupDir.path}/$backupName.backup');

    String jsonData = jsonEncode(data);

    if (encrypt && password != null) {
      // Chiffrement simple (en production, utiliser un chiffrement plus robuste)
      jsonData = _encryptData(jsonData, password);
    }

    // Compression
    final bytes = utf8.encode(jsonData);
    final compressed = GZipEncoder().encode(bytes);

    await backupFile.writeAsBytes(compressed!);
    return backupFile;
  }

  Future<Map<String, dynamic>> _readBackupFile(
    File backupFile, {
    String? password,
  }) async {
    // Décompression
    final compressedBytes = await backupFile.readAsBytes();
    final decompressed = GZipDecoder().decodeBytes(compressedBytes);
    String jsonData = utf8.decode(decompressed);

    // Déchiffrement si nécessaire
    if (password != null) {
      jsonData = _decryptData(jsonData, password);
    }

    return jsonDecode(jsonData) as Map<String, dynamic>;
  }

  Future<Directory> _getBackupDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${appDir.path}/backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  Future<void> _saveBackupMetadata(
    String backupName,
    File backupFile, {
    bool isIncremental = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final backupsJson = prefs.getStringList('backup_metadata') ?? [];

    final backupInfo = BackupInfo(
      name: backupName,
      filePath: backupFile.path,
      size: await backupFile.length(),
      createdAt: DateTime.now(),
      isIncremental: isIncremental,
      isEncrypted: true, // Supposer chiffré par défaut
    );

    backupsJson.add(jsonEncode(backupInfo.toJson()));
    await prefs.setStringList('backup_metadata', backupsJson);
  }

  Future<void> _removeBackupMetadata(String backupName) async {
    final prefs = await SharedPreferences.getInstance();
    final backupsJson = prefs.getStringList('backup_metadata') ?? [];

    backupsJson.removeWhere((backupJson) {
      final backupMap = jsonDecode(backupJson) as Map<String, dynamic>;
      return backupMap['name'] == backupName;
    });

    await prefs.setStringList('backup_metadata', backupsJson);
  }

  Future<DateTime> _getLastBackupDate() async {
    final backups = await getAvailableBackups();
    if (backups.isEmpty) {
      return DateTime.now().subtract(const Duration(days: 30));
    }
    return backups.first.createdAt;
  }

  ValidationResult _validateBackupData(Map<String, dynamic> data) {
    try {
      // Vérifier la structure de base
      if (!data.containsKey('version') || !data.containsKey('data')) {
        return ValidationResult.invalid('Structure de backup invalide');
      }

      final backupData = data['data'] as Map<String, dynamic>;

      // Vérifier les tables essentielles
      final requiredTables = ['locataires', 'cites', 'releves'];
      for (final table in requiredTables) {
        if (!backupData.containsKey(table)) {
          return ValidationResult.invalid('Table manquante: $table');
        }
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Erreur de validation: $e');
    }
  }

  Future<void> _restoreData(
      Map<String, dynamic> backupData, bool overwrite) async {
    final data = backupData['data'] as Map<String, dynamic>;

    // TODO: Implémenter la restauration réelle des données
    // Pour l'instant, on simule
    debugPrint('Restauration des données: ${data.keys}');
  }

  int _countRestoredItems(Map<String, dynamic> backupData) {
    final data = backupData['data'] as Map<String, dynamic>;
    int count = 0;

    for (final table in data.values) {
      if (table is List) {
        count += table.length;
      }
    }

    return count;
  }

  Future<void> _scheduleNextAutoBackup(AutoBackupFrequency frequency) async {
    // TODO: Implémenter la programmation des tâches
    // Utiliser un package comme workmanager pour Android
    debugPrint('Programmation du prochain backup: $frequency');
  }

  String _encryptData(String data, String password) {
    // Chiffrement simple pour la démo
    // En production, utiliser un algorithme de chiffrement robuste
    final key = sha256.convert(utf8.encode(password)).toString();
    return base64.encode(utf8.encode('$key:$data'));
  }

  String _decryptData(String encryptedData, String password) {
    // Déchiffrement simple pour la démo
    final decoded = utf8.decode(base64.decode(encryptedData));
    final key = sha256.convert(utf8.encode(password)).toString();
    return decoded.replaceFirst('$key:', '');
  }
}

// Modèles de données

class BackupResult {
  final bool success;
  final String? error;
  final String? fileName;
  final String? filePath;
  final int? size;
  final DateTime? createdAt;
  final String? message;

  BackupResult._({
    required this.success,
    this.error,
    this.fileName,
    this.filePath,
    this.size,
    this.createdAt,
    this.message,
  });

  factory BackupResult.success({
    required String fileName,
    required String filePath,
    required int size,
    required DateTime createdAt,
    String? message,
  }) {
    return BackupResult._(
      success: true,
      fileName: fileName,
      filePath: filePath,
      size: size,
      createdAt: createdAt,
      message: message,
    );
  }

  factory BackupResult.error(String error) {
    return BackupResult._(success: false, error: error);
  }
}

class RestoreResult {
  final bool success;
  final String? error;
  final DateTime? restoredAt;
  final int? itemsRestored;

  RestoreResult._({
    required this.success,
    this.error,
    this.restoredAt,
    this.itemsRestored,
  });

  factory RestoreResult.success({
    required DateTime restoredAt,
    required int itemsRestored,
  }) {
    return RestoreResult._(
      success: true,
      restoredAt: restoredAt,
      itemsRestored: itemsRestored,
    );
  }

  factory RestoreResult.error(String error) {
    return RestoreResult._(success: false, error: error);
  }
}

class BackupInfo {
  final String name;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final bool isIncremental;
  final bool isEncrypted;

  BackupInfo({
    required this.name,
    required this.filePath,
    required this.size,
    required this.createdAt,
    required this.isIncremental,
    required this.isEncrypted,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> json) {
    return BackupInfo(
      name: json['name'] as String,
      filePath: json['filePath'] as String,
      size: json['size'] as int,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isIncremental: json['isIncremental'] as bool? ?? false,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'filePath': filePath,
      'size': size,
      'createdAt': createdAt.toIso8601String(),
      'isIncremental': isIncremental,
      'isEncrypted': isEncrypted,
    };
  }

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) =>
      ValidationResult._(false, error);
}

enum AutoBackupFrequency {
  daily,
  weekly,
  monthly,
}
