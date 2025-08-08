import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:rentilax_tracker/l10n/generated/app_localizations.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../models/cite.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateMonthlyReport({
    required List<Releve> releves,
    required List<Locataire> locataires,
    required List<Cite> cites,
    required Configuration configuration,
    required int month,
    required int year,
    required AppLocalizations localizations,
  }) async {
    final pdf = pw.Document();

    final String monthName =
        DateFormat.MMMM(localizations.localeName).format(DateTime(year, month));

    // Dimensions optimisées pour 8 reçus par page (2 colonnes x 4 lignes)
    // A4: 210mm x 297mm avec marges
    const double pageWidth = 210 * PdfPageFormat.mm;
    const double pageHeight = 297 * PdfPageFormat.mm;
    const double margin = 10 * PdfPageFormat.mm;
    const double headerHeight = 30 * PdfPageFormat.mm;

    const double receiptWidth = (pageWidth - (3 * margin)) / 2; // ~95mm
    const double receiptHeight =
        (pageHeight - headerHeight - (5 * margin)) / 4; // ~60mm

    // Fonction pour créer un reçu avec un design amélioré
    pw.Widget buildReceipt(Releve releve, Locataire locataire,
        Configuration config, List<Cite> allCites) {
      final cite = allCites.firstWhere((c) => c.id == locataire.citeId,
          orElse: () =>
              Cite(nom: localizations.unknown, dateCreation: DateTime.now()));

      return pw.Container(
        width: receiptWidth,
        height: receiptHeight,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey700, width: 1),
          borderRadius: pw.BorderRadius.circular(4),
          color: PdfColors.grey50,
        ),
        padding: const pw.EdgeInsets.all(6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // En-tête du reçu
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue900,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Text(
                localizations.receiptOfConsumption,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 9,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Informations du locataire
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    locataire.nomComplet,
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey900,
                    ),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${localizations.city}: ${cite.nom}',
                          style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(
                          '${localizations.log}: ${locataire.numeroLogement}',
                          style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                ],
              ),
            ),

            // Période et mois de relevé
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    '${localizations.month}: ${DateFormat('MMMM yyyy', localizations.localeName).format(releve.moisReleve)}',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  pw.Text(
                    '${localizations.createdOn}: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}',
                    style: const pw.TextStyle(
                        fontSize: 6, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),

            // Données de consommation
            pw.Container(
              child: pw.Column(
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${localizations.oldIndex}:',
                          style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(releve.ancienIndex.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${localizations.newIndex}:',
                          style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(releve.nouvelIndex.toStringAsFixed(2),
                          style: const pw.TextStyle(fontSize: 7)),
                    ],
                  ),
                  pw.Divider(color: PdfColors.grey400, thickness: 0.5),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('${localizations.consumption}:',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Text(
                          '${releve.consommation.toStringAsFixed(2)} ${localizations.units}',
                          style: pw.TextStyle(
                              fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            // Montant total
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.green700,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Text(
                '${releve.montant.toStringAsFixed(2)} ${config.devise}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),

            // Commentaire si présent
            if (releve.commentaire != null && releve.commentaire!.isNotEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(2),
                decoration: pw.BoxDecoration(
                  color: PdfColors.yellow50,
                  borderRadius: pw.BorderRadius.circular(2),
                  border: pw.Border.all(color: PdfColors.yellow200, width: 0.5),
                ),
                child: pw.Text(
                  '${localizations.note}: ${releve.commentaire}',
                  style: pw.TextStyle(
                    fontSize: 6,
                    fontStyle: pw.FontStyle.italic,
                    color: PdfColors.grey700,
                  ),
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                ),
              ),
            // Statut de paiement
            pw.Container(
              width: double.infinity,
              padding:
                  const pw.EdgeInsets.symmetric(vertical: 2, horizontal: 4),
              decoration: pw.BoxDecoration(
                color: releve.isPaid ? PdfColors.green100 : PdfColors.red100,
                borderRadius: pw.BorderRadius.circular(2),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${localizations.status}: ${releve.isPaid ? localizations.paid : localizations.unpaid}',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color:
                          releve.isPaid ? PdfColors.green800 : PdfColors.red800,
                    ),
                  ),
                  if (releve.isPaid && releve.paymentDate != null)
                    pw.Text(
                      '${localizations.on}: ${DateFormat('dd/MM/yyyy').format(releve.paymentDate!)}',
                      style: const pw.TextStyle(
                        fontSize: 6,
                        color: PdfColors.grey600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Grouper les relevés par pages de 8 (2 colonnes x 4 lignes)
    for (int i = 0; i < releves.length; i += 8) {
      final List<Releve> pageReleves =
          releves.sublist(i, (i + 8 > releves.length) ? releves.length : i + 8);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(margin),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                // En-tête de la page
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue900,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        localizations.consumptionReport,
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '$monthName $year',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        localizations.pageNumber((i ~/ 8) + 1),
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.blue100,
                        ),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        '${localizations.totalAmount}: ${releves.fold(0.0, (sum, item) => sum + item.montant).toStringAsFixed(2)} ${configuration.devise}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        '${localizations.totalPaidAmount}: ${releves.where((r) => r.isPaid).fold(0.0, (sum, item) => sum + item.montant).toStringAsFixed(2)} ${configuration.devise}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.green200,
                        ),
                      ),
                      pw.Text(
                        '${localizations.totalUnpaidAmount}: ${releves.where((r) => !r.isPaid).fold(0.0, (sum, item) => sum + item.montant).toStringAsFixed(2)} ${configuration.devise}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.red200,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 8),

                // Grille de reçus (2 colonnes x 4 lignes)
                pw.Expanded(
                  child: pw.Column(
                    children: List.generate(4, (rowIndex) {
                      return pw.Expanded(
                        child: pw.Row(
                          children: List.generate(2, (colIndex) {
                            final releveIndex = rowIndex * 2 + colIndex;
                            if (releveIndex < pageReleves.length) {
                              final releve = pageReleves[releveIndex];
                              final locataire = locataires.firstWhere(
                                  (l) => l.id == releve.locataireId);
                              return pw.Expanded(
                                child: pw.Padding(
                                  padding: pw.EdgeInsets.all(2),
                                  child: buildReceipt(
                                      releve, locataire, configuration, cites),
                                ),
                              );
                            } else {
                              // Espace vide pour les emplacements non utilisés
                              return pw.Expanded(
                                child: pw.Container(),
                              );
                            }
                          }),
                        ),
                      );
                    }),
                  ),
                ),

                // Pied de page
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        localizations.generatedOn(DateFormat('dd/MM/yyyy HH:mm')
                            .format(DateTime.now())),
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey600),
                      ),
                      pw.Text(
                        localizations.totalReadings(releves.length),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
