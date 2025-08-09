import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../models/releve.dart';
import '../models/unit_type.dart';
import 'database_service.dart';

class ImportService {
  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Sélectionne et analyse un fichier pour l'import
  Future<ImportAnalysisResult> analyzeFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return ImportAnalysisResult.error('Aucun fichier sélectionné');
      }

      final file = File(result.files.first.path!);
      final fileName = result.files.first.name;
      final fileExtension = fileName.split('.').last.toLowerCase();

      // Analyser le fichier selon son type
      switch (fileExtension) {
        case 'csv':
          return await _analyzeCSVFile(file, fileName);
        case 'xlsx':
          return await _analyzeExcelFile(file, fileName);
        case 'json':
          return await _analyzeJSONFile(file, fileName);
        default:
          return ImportAnalysisResult.error(
              'Format de fichier non supporté: $fileExtension');
      }
    } catch (e) {
      return ImportAnalysisResult.error(
          'Erreur lors de l\'analyse du fichier: $e');
    }
  }

  /// Importe des données après validation
  Future<ImportResult> importData(ImportConfiguration config) async {
    try {
      final file = File(config.filePath);
      if (!await file.exists()) {
        return ImportResult.error('Fichier introuvable');
      }

      // Valider la configuration
      final validationResult = _validateImportConfiguration(config);
      if (!validationResult.isValid) {
        return ImportResult.error(
            'Configuration invalide: ${validationResult.errors.first}');
      }

      // Importer selon le type de données
      switch (config.dataType) {
        case ImportDataType.locataires:
          return await _importLocataires(config);
        case ImportDataType.cites:
          return await _importCites(config);
        case ImportDataType.releves:
          return await _importReleves(config);
        case ImportDataType.mixed:
          return await _importMixedData(config);
      }
    } catch (e) {
      return ImportResult.error('Erreur lors de l\'import: $e');
    }
  }

  /// Valide les données avant import
  Future<ValidationResult> validateImportData(
      ImportConfiguration config) async {
    try {
      final file = File(config.filePath);
      final data = await _readFileData(file, config.fileFormat);

      final errors = <String>[];
      final warnings = <String>[];

      // Valider chaque ligne de données
      for (int i = 0; i < data.length; i++) {
        final row = data[i];
        final lineNumber =
            i + 2; // +2 car ligne 1 = en-têtes, index commence à 0

        final lineValidation = _validateDataRow(row, config, lineNumber);
        errors.addAll(lineValidation.errors);
        warnings.addAll(lineValidation.warnings);
      }

      return ValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
        totalRows: data.length,
        validRows: data.length - errors.length,
      );
    } catch (e) {
      return ValidationResult(
        isValid: false,
        errors: ['Erreur lors de la validation: $e'],
        warnings: [],
        totalRows: 0,
        validRows: 0,
      );
    }
  }

  /// Obtient un aperçu des données à importer
  Future<List<Map<String, dynamic>>> getImportPreview(
    String filePath,
    ImportFileFormat format, {
    int maxRows = 10,
  }) async {
    try {
      final file = File(filePath);
      final allData = await _readFileData(file, format);

      // Retourner seulement les premières lignes pour l'aperçu
      return allData.take(maxRows).toList();
    } catch (e) {
      debugPrint('Erreur lors de la génération de l\'aperçu: $e');
      return [];
    }
  }

  /// Suggère un mapping automatique des colonnes
  Map<String, String> suggestColumnMapping(
    List<String> fileColumns,
    ImportDataType dataType,
  ) {
    final mapping = <String, String>{};

    switch (dataType) {
      case ImportDataType.locataires:
        mapping.addAll(_suggestLocataireMapping(fileColumns));
        break;
      case ImportDataType.cites:
        mapping.addAll(_suggestCiteMapping(fileColumns));
        break;
      case ImportDataType.releves:
        mapping.addAll(_suggestReleveMapping(fileColumns));
        break;
      case ImportDataType.mixed:
        // Pour les données mixtes, essayer de détecter automatiquement
        break;
    }

    return mapping;
  }

  // Méthodes privées d'analyse

  Future<ImportAnalysisResult> _analyzeCSVFile(
      File file, String fileName) async {
    try {
      final content = await file.readAsString();
      final rows = const CsvToListConverter().convert(content);

      if (rows.isEmpty) {
        return ImportAnalysisResult.error('Fichier CSV vide');
      }

      final headers = rows.first.map((e) => e.toString()).toList();
      final dataRows = rows.skip(1).toList();

      return ImportAnalysisResult.success(
        fileName: fileName,
        filePath: file.path,
        fileFormat: ImportFileFormat.csv,
        headers: headers,
        rowCount: dataRows.length,
        dataType: _detectDataType(headers),
        sampleData: dataRows.take(5).map((row) {
          final map = <String, dynamic>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            map[headers[i]] = row[i];
          }
          return map;
        }).toList(),
      );
    } catch (e) {
      return ImportAnalysisResult.error('Erreur lors de l\'analyse du CSV: $e');
    }
  }

  Future<ImportAnalysisResult> _analyzeExcelFile(
      File file, String fileName) async {
    try {
      final bytes = await file.readAsBytes();
      final excel = Excel.decodeBytes(bytes);

      if (excel.tables.isEmpty) {
        return ImportAnalysisResult.error('Fichier Excel vide');
      }

      // Utiliser la première feuille
      final sheetName = excel.tables.keys.first;
      final sheet = excel.tables[sheetName]!;

      if (sheet.rows.isEmpty) {
        return ImportAnalysisResult.error('Feuille Excel vide');
      }

      final headers = sheet.rows.first
          .map((cell) => cell?.value?.toString() ?? '')
          .toList();
      final dataRows = sheet.rows.skip(1).toList();

      return ImportAnalysisResult.success(
        fileName: fileName,
        filePath: file.path,
        fileFormat: ImportFileFormat.excel,
        headers: headers,
        rowCount: dataRows.length,
        dataType: _detectDataType(headers),
        sampleData: dataRows.take(5).map((row) {
          final map = <String, dynamic>{};
          for (int i = 0; i < headers.length && i < row.length; i++) {
            map[headers[i]] = row[i]?.value;
          }
          return map;
        }).toList(),
      );
    } catch (e) {
      return ImportAnalysisResult.error(
          'Erreur lors de l\'analyse du Excel: $e');
    }
  }

  Future<ImportAnalysisResult> _analyzeJSONFile(
      File file, String fileName) async {
    try {
      final content = await file.readAsString();
      final jsonData = jsonDecode(content);

      if (jsonData is! List) {
        return ImportAnalysisResult.error(
            'Le fichier JSON doit contenir un tableau');
      }

      final dataList = jsonData;
      if (dataList.isEmpty) {
        return ImportAnalysisResult.error('Fichier JSON vide');
      }

      final firstItem = dataList.first as Map<String, dynamic>;
      final headers = firstItem.keys.toList();

      return ImportAnalysisResult.success(
        fileName: fileName,
        filePath: file.path,
        fileFormat: ImportFileFormat.json,
        headers: headers,
        rowCount: dataList.length,
        dataType: _detectDataType(headers),
        sampleData: dataList.take(5).cast<Map<String, dynamic>>().toList(),
      );
    } catch (e) {
      return ImportAnalysisResult.error(
          'Erreur lors de l\'analyse du JSON: $e');
    }
  }

  ImportDataType _detectDataType(List<String> headers) {
    final lowerHeaders = headers.map((h) => h.toLowerCase()).toList();

    // Détecter les locataires
    if (lowerHeaders.any((h) => h.contains('nom') || h.contains('locataire')) &&
        lowerHeaders
            .any((h) => h.contains('telephone') || h.contains('email'))) {
      return ImportDataType.locataires;
    }

    // Détecter les cités
    if (lowerHeaders.any((h) => h.contains('cite') || h.contains('cité')) &&
        lowerHeaders.length <= 5) {
      return ImportDataType.cites;
    }

    // Détecter les relevés
    if (lowerHeaders
            .any((h) => h.contains('consommation') || h.contains('montant')) &&
        lowerHeaders.any((h) => h.contains('releve') || h.contains('relevé'))) {
      return ImportDataType.releves;
    }

    return ImportDataType.mixed;
  }

  // Méthodes privées d'import

  Future<ImportResult> _importLocataires(ImportConfiguration config) async {
    try {
      final file = File(config.filePath);
      final data = await _readFileData(file, config.fileFormat);

      int imported = 0;
      int skipped = 0;
      final errors = <String>[];

      for (int i = 0; i < data.length; i++) {
        try {
          final row = data[i];
          final locataire = _createLocataireFromRow(row, config.columnMapping);

          if (locataire != null) {
            await _databaseService.insertLocataire(locataire);
            imported++;
          } else {
            skipped++;
          }
        } catch (e) {
          errors.add('Ligne ${i + 2}: $e');
          skipped++;
        }
      }

      return ImportResult.success(
        importedCount: imported,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.error('Erreur lors de l\'import des locataires: $e');
    }
  }

  Future<ImportResult> _importCites(ImportConfiguration config) async {
    try {
      final file = File(config.filePath);
      final data = await _readFileData(file, config.fileFormat);

      int imported = 0;
      int skipped = 0;
      final errors = <String>[];

      for (int i = 0; i < data.length; i++) {
        try {
          final row = data[i];
          final cite = _createCiteFromRow(row, config.columnMapping);

          if (cite != null) {
            await _databaseService.insertCite(cite);
            imported++;
          } else {
            skipped++;
          }
        } catch (e) {
          errors.add('Ligne ${i + 2}: $e');
          skipped++;
        }
      }

      return ImportResult.success(
        importedCount: imported,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.error('Erreur lors de l\'import des cités: $e');
    }
  }

  Future<ImportResult> _importReleves(ImportConfiguration config) async {
    try {
      final file = File(config.filePath);
      final data = await _readFileData(file, config.fileFormat);

      int imported = 0;
      int skipped = 0;
      final errors = <String>[];

      for (int i = 0; i < data.length; i++) {
        try {
          final row = data[i];
          final releve = await _createReleveFromRow(row, config.columnMapping);

          if (releve != null) {
            await _databaseService.insertReleve(releve);
            imported++;
          } else {
            skipped++;
          }
        } catch (e) {
          errors.add('Ligne ${i + 2}: $e');
          skipped++;
        }
      }

      return ImportResult.success(
        importedCount: imported,
        skippedCount: skipped,
        errors: errors,
      );
    } catch (e) {
      return ImportResult.error('Erreur lors de l\'import des relevés: $e');
    }
  }

  Future<ImportResult> _importMixedData(ImportConfiguration config) async {
    // Pour les données mixtes, essayer d'importer selon le type détecté pour chaque ligne
    return ImportResult.error('Import de données mixtes non encore implémenté');
  }

  // Méthodes utilitaires

  Future<List<Map<String, dynamic>>> _readFileData(
      File file, ImportFileFormat format) async {
    switch (format) {
      case ImportFileFormat.csv:
        return await _readCSVData(file);
      case ImportFileFormat.excel:
        return await _readExcelData(file);
      case ImportFileFormat.json:
        return await _readJSONData(file);
    }
  }

  Future<List<Map<String, dynamic>>> _readCSVData(File file) async {
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content);

    if (rows.isEmpty) return [];

    final headers = rows.first.map((e) => e.toString()).toList();
    final dataRows = rows.skip(1).toList();

    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i];
      }
      return map;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _readExcelData(File file) async {
    final bytes = await file.readAsBytes();
    final excel = Excel.decodeBytes(bytes);

    if (excel.tables.isEmpty) return [];

    final sheetName = excel.tables.keys.first;
    final sheet = excel.tables[sheetName]!;

    if (sheet.rows.isEmpty) return [];

    final headers =
        sheet.rows.first.map((cell) => cell?.value?.toString() ?? '').toList();
    final dataRows = sheet.rows.skip(1).toList();

    return dataRows.map((row) {
      final map = <String, dynamic>{};
      for (int i = 0; i < headers.length && i < row.length; i++) {
        map[headers[i]] = row[i]?.value;
      }
      return map;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _readJSONData(File file) async {
    final content = await file.readAsString();
    final jsonData = jsonDecode(content) as List;
    return jsonData.cast<Map<String, dynamic>>();
  }

  Locataire? _createLocataireFromRow(
      Map<String, dynamic> row, Map<String, String> mapping) {
    try {
      final nomComplet =
          _getValueFromMapping(row, mapping, 'nomComplet') as String?;
      final citeNom = _getValueFromMapping(row, mapping, 'cite') as String?;
      final telephone =
          _getValueFromMapping(row, mapping, 'telephone') as String?;
      final email = _getValueFromMapping(row, mapping, 'email') as String?;

      if (nomComplet == null || nomComplet.isEmpty) return null;
      if (citeNom == null || citeNom.isEmpty) return null;

      // TODO: Récupérer l'ID de la cité depuis la base de données
      // Pour l'instant, on utilise un ID par défaut
      const citeId = 1;

      return Locataire(
        nom: nomComplet.split(' ').first,
        prenom: nomComplet.split(' ').skip(1).join(' '),
        citeId: citeId,
        numeroLogement: 'N/A',
        contact: telephone,
        email: email,
        dateEntree: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la création du locataire: $e');
      return null;
    }
  }

  Cite? _createCiteFromRow(
      Map<String, dynamic> row, Map<String, String> mapping) {
    try {
      final nom = _getValueFromMapping(row, mapping, 'nom') as String?;
      final adresse = _getValueFromMapping(row, mapping, 'adresse') as String?;

      if (nom == null || nom.isEmpty) return null;

      return Cite(
        nom: nom,
        adresse: adresse,
        dateCreation: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la création de la cité: $e');
      return null;
    }
  }

  Future<Releve?> _createReleveFromRow(
      Map<String, dynamic> row, Map<String, String> mapping) async {
    try {
      final locataireNom =
          _getValueFromMapping(row, mapping, 'locataire') as String?;
      final consommationStr =
          _getValueFromMapping(row, mapping, 'consommation')?.toString();
      final montantStr =
          _getValueFromMapping(row, mapping, 'montant')?.toString();
      final dateReleveStr =
          _getValueFromMapping(row, mapping, 'dateReleve') as String?;
      final moisReleveStr =
          _getValueFromMapping(row, mapping, 'moisReleve') as String?;
      final isPaidStr =
          _getValueFromMapping(row, mapping, 'isPaid')?.toString();

      if (locataireNom == null ||
          consommationStr == null ||
          montantStr == null) {
        return null;
      }

      final consommation = double.tryParse(consommationStr) ?? 0.0;
      final montant = double.tryParse(montantStr) ?? 0.0;
      final dateReleve = _parseDate(dateReleveStr) ?? DateTime.now();
      final moisReleve = _parseDate(moisReleveStr) ?? DateTime.now();
      final isPaid = _parseBool(isPaidStr) ?? false;

      // TODO: Récupérer l'ID du locataire depuis la base de données
      // Pour l'instant, on utilise un ID par défaut
      const locataireId = 1;

      return Releve(
        locataireId: locataireId,
        ancienIndex: 0.0,
        nouvelIndex: consommation,
        tarif: 100.0,
        dateReleve: dateReleve,
        moisReleve: moisReleve,
        commentaire: null,
        isPaid: isPaid,
        paymentDate: null,
        paidAmount: 0.0,
        unitId: null,
        unitType: UnitType.water,
      );
    } catch (e) {
      debugPrint('Erreur lors de la création du relevé: $e');
      return null;
    }
  }

  dynamic _getValueFromMapping(
      Map<String, dynamic> row, Map<String, String> mapping, String field) {
    final columnName = mapping[field];
    if (columnName == null) return null;
    return row[columnName];
  }

  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Essayer différents formats de date
      final formats = [
        'dd/MM/yyyy',
        'MM/dd/yyyy',
        'yyyy-MM-dd',
        'dd-MM-yyyy',
        'MM-dd-yyyy',
      ];

      for (final format in formats) {
        try {
          return DateFormat(format).parse(dateStr);
        } catch (e) {
          continue;
        }
      }

      // Essayer le parsing par défaut
      return DateTime.parse(dateStr);
    } catch (e) {
      debugPrint('Impossible de parser la date: $dateStr');
      return null;
    }
  }

  bool? _parseBool(String? boolStr) {
    if (boolStr == null || boolStr.isEmpty) return null;

    final lower = boolStr.toLowerCase();
    if (lower == 'true' || lower == '1' || lower == 'oui' || lower == 'yes') {
      return true;
    } else if (lower == 'false' ||
        lower == '0' ||
        lower == 'non' ||
        lower == 'no') {
      return false;
    }

    return null;
  }

  Map<String, String> _suggestLocataireMapping(List<String> columns) {
    final mapping = <String, String>{};
    final lowerColumns = columns.map((c) => c.toLowerCase()).toList();

    // Nom complet
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('nom') &&
          (col.contains('complet') || col.contains('full'))) {
        mapping['nomComplet'] = columns[i];
        break;
      } else if (col == 'nom' || col == 'name') {
        mapping['nomComplet'] = columns[i];
        break;
      }
    }

    // Cité
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('cite') || col.contains('cité')) {
        mapping['cite'] = columns[i];
        break;
      }
    }

    // Téléphone
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('telephone') ||
          col.contains('phone') ||
          col.contains('tel')) {
        mapping['telephone'] = columns[i];
        break;
      }
    }

    // Email
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('email') || col.contains('mail')) {
        mapping['email'] = columns[i];
        break;
      }
    }

    return mapping;
  }

  Map<String, String> _suggestCiteMapping(List<String> columns) {
    final mapping = <String, String>{};
    final lowerColumns = columns.map((c) => c.toLowerCase()).toList();

    // Nom
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col == 'nom' || col == 'name' || col.contains('cite')) {
        mapping['nom'] = columns[i];
        break;
      }
    }

    // Adresse
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('adresse') || col.contains('address')) {
        mapping['adresse'] = columns[i];
        break;
      }
    }

    return mapping;
  }

  Map<String, String> _suggestReleveMapping(List<String> columns) {
    final mapping = <String, String>{};
    final lowerColumns = columns.map((c) => c.toLowerCase()).toList();

    // Locataire
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('locataire') || col.contains('tenant')) {
        mapping['locataire'] = columns[i];
        break;
      }
    }

    // Consommation
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('consommation') || col.contains('consumption')) {
        mapping['consommation'] = columns[i];
        break;
      }
    }

    // Montant
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('montant') ||
          col.contains('amount') ||
          col.contains('prix')) {
        mapping['montant'] = columns[i];
        break;
      }
    }

    // Date relevé
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('date') && col.contains('releve')) {
        mapping['dateReleve'] = columns[i];
        break;
      }
    }

    // Mois relevé
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('mois') && col.contains('releve')) {
        mapping['moisReleve'] = columns[i];
        break;
      }
    }

    // Payé
    for (int i = 0; i < lowerColumns.length; i++) {
      final col = lowerColumns[i];
      if (col.contains('paye') ||
          col.contains('paid') ||
          col.contains('statut')) {
        mapping['isPaid'] = columns[i];
        break;
      }
    }

    return mapping;
  }

  ValidationResult _validateImportConfiguration(ImportConfiguration config) {
    final errors = <String>[];

    if (config.filePath.isEmpty) {
      errors.add('Chemin de fichier manquant');
    }

    if (config.columnMapping.isEmpty) {
      errors.add('Mapping des colonnes manquant');
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: [],
      totalRows: 0,
      validRows: 0,
    );
  }

  RowValidationResult _validateDataRow(
    Map<String, dynamic> row,
    ImportConfiguration config,
    int lineNumber,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validation spécifique selon le type de données
    switch (config.dataType) {
      case ImportDataType.locataires:
        final nom =
            _getValueFromMapping(row, config.columnMapping, 'nomComplet');
        if (nom == null || nom.toString().isEmpty) {
          errors.add('Ligne $lineNumber: Nom du locataire manquant');
        }
        break;

      case ImportDataType.cites:
        final nom = _getValueFromMapping(row, config.columnMapping, 'nom');
        if (nom == null || nom.toString().isEmpty) {
          errors.add('Ligne $lineNumber: Nom de la cité manquant');
        }
        break;

      case ImportDataType.releves:
        final consommation =
            _getValueFromMapping(row, config.columnMapping, 'consommation');
        final montant =
            _getValueFromMapping(row, config.columnMapping, 'montant');

        if (consommation == null) {
          errors.add('Ligne $lineNumber: Consommation manquante');
        } else if (double.tryParse(consommation.toString()) == null) {
          errors.add('Ligne $lineNumber: Consommation invalide');
        }

        if (montant == null) {
          errors.add('Ligne $lineNumber: Montant manquant');
        } else if (double.tryParse(montant.toString()) == null) {
          errors.add('Ligne $lineNumber: Montant invalide');
        }
        break;

      case ImportDataType.mixed:
        warnings.add('Ligne $lineNumber: Type de données mixte non validé');
        break;
    }

    return RowValidationResult(
      errors: errors,
      warnings: warnings,
    );
  }
}

// Modèles de données

class ImportAnalysisResult {
  final bool success;
  final String? error;
  final String? fileName;
  final String? filePath;
  final ImportFileFormat? fileFormat;
  final List<String>? headers;
  final int? rowCount;
  final ImportDataType? dataType;
  final List<Map<String, dynamic>>? sampleData;

  ImportAnalysisResult._({
    required this.success,
    this.error,
    this.fileName,
    this.filePath,
    this.fileFormat,
    this.headers,
    this.rowCount,
    this.dataType,
    this.sampleData,
  });

  factory ImportAnalysisResult.success({
    required String fileName,
    required String filePath,
    required ImportFileFormat fileFormat,
    required List<String> headers,
    required int rowCount,
    required ImportDataType dataType,
    required List<Map<String, dynamic>> sampleData,
  }) {
    return ImportAnalysisResult._(
      success: true,
      fileName: fileName,
      filePath: filePath,
      fileFormat: fileFormat,
      headers: headers,
      rowCount: rowCount,
      dataType: dataType,
      sampleData: sampleData,
    );
  }

  factory ImportAnalysisResult.error(String error) {
    return ImportAnalysisResult._(success: false, error: error);
  }
}

class ImportResult {
  final bool success;
  final String? error;
  final int? importedCount;
  final int? skippedCount;
  final List<String>? errors;

  ImportResult._({
    required this.success,
    this.error,
    this.importedCount,
    this.skippedCount,
    this.errors,
  });

  factory ImportResult.success({
    required int importedCount,
    required int skippedCount,
    required List<String> errors,
  }) {
    return ImportResult._(
      success: true,
      importedCount: importedCount,
      skippedCount: skippedCount,
      errors: errors,
    );
  }

  factory ImportResult.error(String error) {
    return ImportResult._(success: false, error: error);
  }
}

class ImportConfiguration {
  final String filePath;
  final ImportFileFormat fileFormat;
  final ImportDataType dataType;
  final Map<String, String> columnMapping;
  final bool skipFirstRow;
  final bool overwriteExisting;

  ImportConfiguration({
    required this.filePath,
    required this.fileFormat,
    required this.dataType,
    required this.columnMapping,
    this.skipFirstRow = true,
    this.overwriteExisting = false,
  });
}

class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final int totalRows;
  final int validRows;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.totalRows,
    required this.validRows,
  });
}

class RowValidationResult {
  final List<String> errors;
  final List<String> warnings;

  RowValidationResult({
    required this.errors,
    required this.warnings,
  });
}

enum ImportFileFormat {
  csv,
  excel,
  json,
}

enum ImportDataType {
  locataires,
  cites,
  releves,
  mixed,
}
