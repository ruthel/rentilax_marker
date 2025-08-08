import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../models/configuration.dart';
import 'database_service.dart';

class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  final DatabaseService _databaseService = DatabaseService();

  /// Exporte un rapport mensuel en PDF
  Future<ExportResult> exportMonthlyReportToPDF({
    required int month,
    required int year,
    ExportTemplate? template,
  }) async {
    try {
      final releves = await _databaseService.getRelevesForMonth(month, year);
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();

      final pdf = pw.Document();

      // Page de couverture
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildCoverPage(month, year, config);
          },
        ),
      );

      // Résumé exécutif
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildExecutiveSummary(releves, locataires, cites);
          },
        ),
      );

      // Détail des relevés
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildRelevesDetails(releves, locataires, cites);
          },
        ),
      );

      // Analyse financière
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildFinancialAnalysis(releves);
          },
        ),
      );

      // Sauvegarder le PDF
      final output = await _getExportDirectory();
      final fileName = 'rapport_mensuel_${month}_${year}.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return ExportResult.success(
        fileName: fileName,
        filePath: file.path,
        size: await file.length(),
        format: ExportFormat.pdf,
      );
    } catch (e) {
      return ExportResult.error('Erreur lors de l\'export PDF: $e');
    }
  }

  /// Exporte un rapport annuel en PDF
  Future<ExportResult> exportAnnualReportToPDF({
    required int year,
    ExportTemplate? template,
  }) async {
    try {
      final allReleves = await _databaseService.getReleves();
      final releves =
          allReleves.where((r) => r.moisReleve.year == year).toList();
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();

      final pdf = pw.Document();

      // Page de couverture
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildAnnualCoverPage(year, config);
          },
        ),
      );

      // Résumé annuel
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildAnnualSummary(releves, locataires, cites);
          },
        ),
      );

      // Analyse par mois
      for (int month = 1; month <= 12; month++) {
        final monthlyReleves =
            releves.where((r) => r.moisReleve.month == month).toList();
        if (monthlyReleves.isNotEmpty) {
          pdf.addPage(
            pw.Page(
              pageFormat: PdfPageFormat.a4,
              build: (pw.Context context) {
                return _buildMonthlyAnalysis(
                    month, year, monthlyReleves, locataires, cites);
              },
            ),
          );
        }
      }

      final output = await _getExportDirectory();
      final fileName = 'rapport_annuel_$year.pdf';
      final file = File('${output.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      return ExportResult.success(
        fileName: fileName,
        filePath: file.path,
        size: await file.length(),
        format: ExportFormat.pdf,
      );
    } catch (e) {
      return ExportResult.error('Erreur lors de l\'export PDF annuel: $e');
    }
  }

  /// Exporte les données en Excel
  Future<ExportResult> exportToExcel({
    required ExcelExportType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final excel = Excel.createExcel();

      switch (type) {
        case ExcelExportType.allReleves:
          await _addRelevesToExcel(excel, startDate, endDate);
          break;
        case ExcelExportType.allLocataires:
          await _addLocatairesToExcel(excel);
          break;
        case ExcelExportType.financialData:
          await _addFinancialDataToExcel(excel, startDate, endDate);
          break;
        case ExcelExportType.consumptionAnalysis:
          await _addConsumptionAnalysisToExcel(excel, startDate, endDate);
          break;
        case ExcelExportType.complete:
          await _addCompleteDataToExcel(excel, startDate, endDate);
          break;
      }

      final output = await _getExportDirectory();
      final fileName =
          'export_${type.name}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      final file = File('${output.path}/$fileName');

      final bytes = excel.save();
      if (bytes != null) {
        await file.writeAsBytes(bytes);
      }

      return ExportResult.success(
        fileName: fileName,
        filePath: file.path,
        size: await file.length(),
        format: ExportFormat.excel,
      );
    } catch (e) {
      return ExportResult.error('Erreur lors de l\'export Excel: $e');
    }
  }

  /// Exporte les données en CSV
  Future<ExportResult> exportToCSV({
    required CSVExportType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      String csvContent = '';

      switch (type) {
        case CSVExportType.releves:
          csvContent = await _generateRelevesCSV(startDate, endDate);
          break;
        case CSVExportType.locataires:
          csvContent = await _generateLocatairesCSV();
          break;
        case CSVExportType.financial:
          csvContent = await _generateFinancialCSV(startDate, endDate);
          break;
        case CSVExportType.consumption:
          csvContent = await _generateConsumptionCSV(startDate, endDate);
          break;
      }

      final output = await _getExportDirectory();
      final fileName =
          'export_${type.name}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${output.path}/$fileName');

      await file.writeAsString(csvContent, encoding: utf8);

      return ExportResult.success(
        fileName: fileName,
        filePath: file.path,
        size: await file.length(),
        format: ExportFormat.csv,
      );
    } catch (e) {
      return ExportResult.error('Erreur lors de l\'export CSV: $e');
    }
  }

  /// Partage un fichier exporté
  Future<void> shareExportedFile(String filePath, String fileName) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'Export Rentilax Tracker: $fileName',
      );
    } catch (e) {
      throw Exception('Erreur lors du partage: $e');
    }
  }

  /// Obtient la liste des exports disponibles
  Future<List<ExportInfo>> getAvailableExports() async {
    try {
      final exportDir = await _getExportDirectory();
      final files = await exportDir.list().toList();

      final exports = <ExportInfo>[];
      for (final file in files) {
        if (file is File) {
          final stat = await file.stat();
          final fileName = file.path.split('/').last;
          final format = _getFormatFromFileName(fileName);

          exports.add(ExportInfo(
            fileName: fileName,
            filePath: file.path,
            size: stat.size,
            createdAt: stat.modified,
            format: format,
          ));
        }
      }

      // Trier par date de création (plus récent en premier)
      exports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return exports;
    } catch (e) {
      return [];
    }
  }

  /// Supprime un fichier d'export
  Future<bool> deleteExport(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Méthodes privées pour PDF

  pw.Widget _buildCoverPage(int month, int year, Configuration? config) {
    final monthName = DateFormat('MMMM', 'fr_FR').format(DateTime(year, month));

    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Rentilax Tracker',
          style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 40),
        pw.Text(
          'RAPPORT MENSUEL',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          '$monthName $year',
          style: pw.TextStyle(fontSize: 20),
        ),
        pw.SizedBox(height: 60),
        pw.Text(
          'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildAnnualCoverPage(int year, Configuration? config) {
    return pw.Column(
      mainAxisAlignment: pw.MainAxisAlignment.center,
      children: [
        pw.Text(
          'Rentilax Tracker',
          style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 40),
        pw.Text(
          'RAPPORT ANNUEL',
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          year.toString(),
          style: pw.TextStyle(fontSize: 20),
        ),
        pw.SizedBox(height: 60),
        pw.Text(
          'Généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildExecutiveSummary(
    List<Releve> releves,
    List<Locataire> locataires,
    List<Cite> cites,
  ) {
    final totalRevenue = releves.fold(0.0, (sum, r) => sum + r.montant);
    final paidRevenue =
        releves.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.montant);
    final totalConsumption =
        releves.fold(0.0, (sum, r) => sum + r.consommation);
    final paymentRate =
        totalRevenue > 0 ? (paidRevenue / totalRevenue * 100) : 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RÉSUMÉ EXÉCUTIF',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        // KPIs principaux
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildKPIBox(
                'Revenus Totaux', '${totalRevenue.toStringAsFixed(0)} FCFA'),
            _buildKPIBox(
                'Revenus Payés', '${paidRevenue.toStringAsFixed(0)} FCFA'),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildKPIBox(
                'Taux de Paiement', '${paymentRate.toStringAsFixed(1)}%'),
            _buildKPIBox('Consommation Totale',
                '${totalConsumption.toStringAsFixed(1)} unités'),
          ],
        ),
        pw.SizedBox(height: 30),

        // Statistiques détaillées
        pw.Text(
          'STATISTIQUES DÉTAILLÉES',
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 10),
        pw.Text('• Nombre de relevés: ${releves.length}'),
        pw.Text('• Nombre de locataires actifs: ${locataires.length}'),
        pw.Text('• Nombre de cités: ${cites.length}'),
        pw.Text('• Relevés payés: ${releves.where((r) => r.isPaid).length}'),
        pw.Text('• Relevés impayés: ${releves.where((r) => !r.isPaid).length}'),
      ],
    );
  }

  pw.Widget _buildKPIBox(String title, String value) {
    return pw.Container(
      width: 200,
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildRelevesDetails(
    List<Releve> releves,
    List<Locataire> locataires,
    List<Cite> cites,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'DÉTAIL DES RELEVÉS',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        // Tableau des relevés
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1),
          },
          children: [
            // En-tête
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Locataire', isHeader: true),
                _buildTableCell('Cité', isHeader: true),
                _buildTableCell('Consommation', isHeader: true),
                _buildTableCell('Montant', isHeader: true),
                _buildTableCell('Statut', isHeader: true),
              ],
            ),

            // Données
            ...releves.take(20).map((releve) {
              final locataire = locataires.firstWhere(
                (l) => l.id == releve.locataireId,
                orElse: () => Locataire(
                  nom: 'Inconnu',
                  prenom: '',
                  citeId: 0,
                  numeroLogement: '',
                  dateEntree: DateTime.now(),
                ),
              );
              final cite = cites.firstWhere(
                (c) => c.id == locataire.citeId,
                orElse: () =>
                    Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
              );

              return pw.TableRow(
                children: [
                  _buildTableCell(locataire.nomComplet),
                  _buildTableCell(cite.nom),
                  _buildTableCell('${releve.consommation.toStringAsFixed(1)}'),
                  _buildTableCell('${releve.montant.toStringAsFixed(0)} FCFA'),
                  _buildTableCell(releve.isPaid ? 'Payé' : 'Impayé'),
                ],
              );
            }).toList(),
          ],
        ),

        if (releves.length > 20) ...[
          pw.SizedBox(height: 10),
          pw.Text('... et ${releves.length - 20} autres relevés'),
        ],
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  pw.Widget _buildFinancialAnalysis(List<Releve> releves) {
    final totalRevenue = releves.fold(0.0, (sum, r) => sum + r.montant);
    final paidRevenue =
        releves.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.montant);
    final unpaidRevenue = totalRevenue - paidRevenue;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ANALYSE FINANCIÈRE',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),
        pw.Text('Revenus totaux: ${totalRevenue.toStringAsFixed(0)} FCFA'),
        pw.Text('Revenus encaissés: ${paidRevenue.toStringAsFixed(0)} FCFA'),
        pw.Text('Revenus en attente: ${unpaidRevenue.toStringAsFixed(0)} FCFA'),
        pw.SizedBox(height: 20),
        pw.Text(
          'Taux de recouvrement: ${totalRevenue > 0 ? (paidRevenue / totalRevenue * 100).toStringAsFixed(1) : 0}%',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  pw.Widget _buildAnnualSummary(
    List<Releve> releves,
    List<Locataire> locataires,
    List<Cite> cites,
  ) {
    // Analyse par mois
    final monthlyData = <int, Map<String, double>>{};
    for (int month = 1; month <= 12; month++) {
      final monthlyReleves =
          releves.where((r) => r.moisReleve.month == month).toList();
      monthlyData[month] = {
        'revenue': monthlyReleves.fold(0.0, (sum, r) => sum + r.montant),
        'paid': monthlyReleves
            .where((r) => r.isPaid)
            .fold(0.0, (sum, r) => sum + r.montant),
        'consumption':
            monthlyReleves.fold(0.0, (sum, r) => sum + r.consommation),
      };
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RÉSUMÉ ANNUEL',
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 20),

        // Tableau mensuel
        pw.Table(
          border: pw.TableBorder.all(),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                _buildTableCell('Mois', isHeader: true),
                _buildTableCell('Revenus', isHeader: true),
                _buildTableCell('Encaissés', isHeader: true),
                _buildTableCell('Consommation', isHeader: true),
              ],
            ),
            ...monthlyData.entries.map((entry) {
              final monthName =
                  DateFormat('MMM', 'fr_FR').format(DateTime(2024, entry.key));
              return pw.TableRow(
                children: [
                  _buildTableCell(monthName),
                  _buildTableCell(
                      '${entry.value['revenue']!.toStringAsFixed(0)} FCFA'),
                  _buildTableCell(
                      '${entry.value['paid']!.toStringAsFixed(0)} FCFA'),
                  _buildTableCell(
                      '${entry.value['consumption']!.toStringAsFixed(1)}'),
                ],
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildMonthlyAnalysis(
    int month,
    int year,
    List<Releve> releves,
    List<Locataire> locataires,
    List<Cite> cites,
  ) {
    final monthName =
        DateFormat('MMMM yyyy', 'fr_FR').format(DateTime(year, month));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'ANALYSE - $monthName',
          style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 15),
        _buildExecutiveSummary(releves, locataires, cites),
      ],
    );
  }

  // Méthodes privées pour Excel

  Future<void> _addRelevesToExcel(
      Excel excel, DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();
    final locataires = await _databaseService.getLocataires();
    final cites = await _databaseService.getCites();

    final sheet = excel['Relevés'];

    // En-têtes
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('ID');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Locataire');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Cité');
    sheet.cell(CellIndex.indexByString('D1')).value =
        TextCellValue('Date Relevé');
    sheet.cell(CellIndex.indexByString('E1')).value =
        TextCellValue('Mois Relevé');
    sheet.cell(CellIndex.indexByString('F1')).value =
        TextCellValue('Consommation');
    sheet.cell(CellIndex.indexByString('G1')).value = TextCellValue('Montant');
    sheet.cell(CellIndex.indexByString('H1')).value = TextCellValue('Payé');

    // Données
    int row = 2;
    for (final releve in releves) {
      final locataire = locataires.firstWhere(
        (l) => l.id == releve.locataireId,
        orElse: () => Locataire(
          nom: 'Inconnu',
          prenom: '',
          citeId: 0,
          numeroLogement: '',
          dateEntree: DateTime.now(),
        ),
      );
      final cite = cites.firstWhere(
        (c) => c.id == locataire.citeId,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );

      sheet.cell(CellIndex.indexByString('A$row')).value =
          IntCellValue(releve.id ?? 0);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(locataire.nomComplet);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(cite.nom);
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(DateFormat('dd/MM/yyyy').format(releve.dateReleve));
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(DateFormat('MM/yyyy').format(releve.moisReleve));
      sheet.cell(CellIndex.indexByString('F$row')).value =
          DoubleCellValue(releve.consommation);
      sheet.cell(CellIndex.indexByString('G$row')).value =
          DoubleCellValue(releve.montant);
      sheet.cell(CellIndex.indexByString('H$row')).value =
          TextCellValue(releve.isPaid ? 'Oui' : 'Non');

      row++;
    }
  }

  Future<void> _addLocatairesToExcel(Excel excel) async {
    final locataires = await _databaseService.getLocataires();
    final cites = await _databaseService.getCites();

    final sheet = excel['Locataires'];

    // En-têtes
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('ID');
    sheet.cell(CellIndex.indexByString('B1')).value =
        TextCellValue('Nom Complet');
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('Cité');
    sheet.cell(CellIndex.indexByString('D1')).value =
        TextCellValue('Téléphone');
    sheet.cell(CellIndex.indexByString('E1')).value = TextCellValue('Email');
    sheet.cell(CellIndex.indexByString('F1')).value =
        TextCellValue('Date Création');

    // Données
    int row = 2;
    for (final locataire in locataires) {
      final cite = cites.firstWhere(
        (c) => c.id == locataire.citeId,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );

      sheet.cell(CellIndex.indexByString('A$row')).value =
          IntCellValue(locataire.id ?? 0);
      sheet.cell(CellIndex.indexByString('B$row')).value =
          TextCellValue(locataire.nomComplet);
      sheet.cell(CellIndex.indexByString('C$row')).value =
          TextCellValue(cite.nom);
      sheet.cell(CellIndex.indexByString('D$row')).value =
          TextCellValue(locataire.contact ?? '');
      sheet.cell(CellIndex.indexByString('E$row')).value =
          TextCellValue(locataire.email ?? '');
      sheet.cell(CellIndex.indexByString('F$row')).value =
          TextCellValue(DateFormat('dd/MM/yyyy').format(locataire.dateEntree));

      row++;
    }
  }

  Future<void> _addFinancialDataToExcel(
      Excel excel, DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();

    final sheet = excel['Données Financières'];

    // Résumé financier
    final totalRevenue = releves.fold(0.0, (sum, r) => sum + r.montant);
    final paidRevenue =
        releves.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.montant);

    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Résumé Financier');
    sheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Revenus Totaux');
    sheet.cell(CellIndex.indexByString('B3')).value =
        DoubleCellValue(totalRevenue);
    sheet.cell(CellIndex.indexByString('A4')).value =
        TextCellValue('Revenus Encaissés');
    sheet.cell(CellIndex.indexByString('B4')).value =
        DoubleCellValue(paidRevenue);
    sheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Revenus en Attente');
    sheet.cell(CellIndex.indexByString('B5')).value =
        DoubleCellValue(totalRevenue - paidRevenue);
    sheet.cell(CellIndex.indexByString('A6')).value =
        TextCellValue('Taux de Recouvrement');
    sheet.cell(CellIndex.indexByString('B6')).value = DoubleCellValue(
        totalRevenue > 0 ? (paidRevenue / totalRevenue * 100) : 0);
  }

  Future<void> _addConsumptionAnalysisToExcel(
      Excel excel, DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();

    final sheet = excel['Analyse Consommation'];

    final totalConsumption =
        releves.fold(0.0, (sum, r) => sum + r.consommation);
    final averageConsumption =
        releves.isNotEmpty ? totalConsumption / releves.length : 0.0;

    sheet.cell(CellIndex.indexByString('A1')).value =
        TextCellValue('Analyse de Consommation');
    sheet.cell(CellIndex.indexByString('A3')).value =
        TextCellValue('Consommation Totale');
    sheet.cell(CellIndex.indexByString('B3')).value =
        DoubleCellValue(totalConsumption);
    sheet.cell(CellIndex.indexByString('A4')).value =
        TextCellValue('Consommation Moyenne');
    sheet.cell(CellIndex.indexByString('B4')).value =
        DoubleCellValue(averageConsumption);
    sheet.cell(CellIndex.indexByString('A5')).value =
        TextCellValue('Nombre de Relevés');
    sheet.cell(CellIndex.indexByString('B5')).value =
        IntCellValue(releves.length);
  }

  Future<void> _addCompleteDataToExcel(
      Excel excel, DateTime? startDate, DateTime? endDate) async {
    await _addRelevesToExcel(excel, startDate, endDate);
    await _addLocatairesToExcel(excel);
    await _addFinancialDataToExcel(excel, startDate, endDate);
    await _addConsumptionAnalysisToExcel(excel, startDate, endDate);
  }

  // Méthodes privées pour CSV

  Future<String> _generateRelevesCSV(
      DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();
    final locataires = await _databaseService.getLocataires();
    final cites = await _databaseService.getCites();

    final buffer = StringBuffer();

    // En-têtes
    buffer.writeln(
        'ID,Locataire,Cité,Date Relevé,Mois Relevé,Consommation,Montant,Payé');

    // Données
    for (final releve in releves) {
      final locataire = locataires.firstWhere(
        (l) => l.id == releve.locataireId,
        orElse: () => Locataire(
          nom: 'Inconnu',
          prenom: '',
          citeId: 0,
          numeroLogement: '',
          dateEntree: DateTime.now(),
        ),
      );
      final cite = cites.firstWhere(
        (c) => c.id == locataire.citeId,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );

      buffer.writeln(
          '${releve.id},"${locataire.nomComplet}","${cite.nom}",${DateFormat('dd/MM/yyyy').format(releve.dateReleve)},${DateFormat('MM/yyyy').format(releve.moisReleve)},${releve.consommation},${releve.montant},${releve.isPaid ? 'Oui' : 'Non'}');
    }

    return buffer.toString();
  }

  Future<String> _generateLocatairesCSV() async {
    final locataires = await _databaseService.getLocataires();
    final cites = await _databaseService.getCites();

    final buffer = StringBuffer();

    // En-têtes
    buffer.writeln('ID,Nom Complet,Cité,Téléphone,Email,Date Création');

    // Données
    for (final locataire in locataires) {
      final cite = cites.firstWhere(
        (c) => c.id == locataire.citeId,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
      );

      buffer.writeln(
          '${locataire.id},"${locataire.nomComplet}","${cite.nom}","${locataire.contact ?? ''}","${locataire.email ?? ''}",${DateFormat('dd/MM/yyyy').format(locataire.dateEntree)}');
    }

    return buffer.toString();
  }

  Future<String> _generateFinancialCSV(
      DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();

    final buffer = StringBuffer();

    final totalRevenue = releves.fold(0.0, (sum, r) => sum + r.montant);
    final paidRevenue =
        releves.where((r) => r.isPaid).fold(0.0, (sum, r) => sum + r.montant);

    buffer.writeln('Métrique,Valeur');
    buffer.writeln('Revenus Totaux,$totalRevenue');
    buffer.writeln('Revenus Encaissés,$paidRevenue');
    buffer.writeln('Revenus en Attente,${totalRevenue - paidRevenue}');
    buffer.writeln(
        'Taux de Recouvrement,${totalRevenue > 0 ? (paidRevenue / totalRevenue * 100) : 0}%');

    return buffer.toString();
  }

  Future<String> _generateConsumptionCSV(
      DateTime? startDate, DateTime? endDate) async {
    final releves = await _databaseService.getReleves();

    final buffer = StringBuffer();

    final totalConsumption =
        releves.fold(0.0, (sum, r) => sum + r.consommation);
    final averageConsumption =
        releves.isNotEmpty ? totalConsumption / releves.length : 0.0;

    buffer.writeln('Métrique,Valeur');
    buffer.writeln('Consommation Totale,$totalConsumption');
    buffer.writeln('Consommation Moyenne,$averageConsumption');
    buffer.writeln('Nombre de Relevés,${releves.length}');

    return buffer.toString();
  }

  // Méthodes utilitaires

  Future<Directory> _getExportDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${appDir.path}/exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    return exportDir;
  }

  ExportFormat _getFormatFromFileName(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return ExportFormat.pdf;
      case 'xlsx':
        return ExportFormat.excel;
      case 'csv':
        return ExportFormat.csv;
      default:
        return ExportFormat.pdf;
    }
  }
}

// Modèles de données

class ExportResult {
  final bool success;
  final String? error;
  final String? fileName;
  final String? filePath;
  final int? size;
  final ExportFormat? format;

  ExportResult._({
    required this.success,
    this.error,
    this.fileName,
    this.filePath,
    this.size,
    this.format,
  });

  factory ExportResult.success({
    required String fileName,
    required String filePath,
    required int size,
    required ExportFormat format,
  }) {
    return ExportResult._(
      success: true,
      fileName: fileName,
      filePath: filePath,
      size: size,
      format: format,
    );
  }

  factory ExportResult.error(String error) {
    return ExportResult._(success: false, error: error);
  }
}

class ExportInfo {
  final String fileName;
  final String filePath;
  final int size;
  final DateTime createdAt;
  final ExportFormat format;

  ExportInfo({
    required this.fileName,
    required this.filePath,
    required this.size,
    required this.createdAt,
    required this.format,
  });

  String get formattedSize {
    if (size < 1024) return '${size}B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)}KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

class ExportTemplate {
  final String name;
  final String description;
  final Map<String, dynamic> settings;

  ExportTemplate({
    required this.name,
    required this.description,
    required this.settings,
  });
}

enum ExportFormat {
  pdf,
  excel,
  csv,
}

enum ExcelExportType {
  allReleves,
  allLocataires,
  financialData,
  consumptionAnalysis,
  complete,
}

enum CSVExportType {
  releves,
  locataires,
  financial,
  consumption,
}
