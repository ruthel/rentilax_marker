import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../models/cite.dart'; // Import the Cite model
import 'package:intl/intl.dart';

class PdfService {
  static Future<void> generateMonthlyReport({
    required List<Releve> releves,
    required List<Locataire> locataires,
    required List<Cite> cites, // Add cites to the parameters
    required Configuration configuration,
    required int month,
    required int year,
  }) async {
    final pdf = pw.Document();

    final String monthName = DateFormat.MMMM('fr_FR').format(DateTime(year, month));

    // Dimensions pour un reçu A7 en paysage sur une page A4 (2x4 grille)
    // A4: 210mm x 297mm
    // Chaque cellule: 105mm x 74.25mm
    const double receiptWidth = 105 * PdfPageFormat.mm;
    const double receiptHeight = 74.25 * PdfPageFormat.mm;

    // Fonction pour créer un seul reçu
    pw.Widget _buildReceipt(Releve releve, Locataire locataire, Configuration config, List<Cite> allCites) {
      final cite = allCites.firstWhere((c) => c.id == locataire.citeId, orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()));
      return pw.Container(
        width: receiptWidth,
        height: receiptHeight,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey500, width: 0.5),
          borderRadius: pw.BorderRadius.circular(2),
        ),
        padding: const pw.EdgeInsets.all(8),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('Reçu de consommation', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.SizedBox(height: 5),
            pw.Text('Locataire: ${locataire.nomComplet}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Cité: ${cite.nom}', style: const pw.TextStyle(fontSize: 8)), // Use cite.nom here
            pw.Text('Logement: ${locataire.numeroLogement}', style: const pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 5),
            pw.Text('Date du relevé: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Ancien index: ${releve.ancienIndex.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Nouvel index: ${releve.nouvelIndex.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 8)),
            pw.Text('Consommation: ${releve.consommation.toStringAsFixed(2)} unités', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            pw.SizedBox(height: 5),
            pw.Text('Montant: ${releve.montant.toStringAsFixed(2)} ${config.devise}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            if (releve.commentaire != null && releve.commentaire!.isNotEmpty)
              pw.Text('Commentaire: ${releve.commentaire}', style: const pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
          ],
        ),
      );
    }

    // Group releves into pages of 8
    for (int i = 0; i < releves.length; i += 8) {
      final List<Releve> pageReleves = releves.sublist(i, (i + 8 > releves.length) ? releves.length : i + 8);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            List<pw.TableRow> rows = [];
            for (int j = 0; j < pageReleves.length; j += 2) {
              List<pw.Widget> rowChildren = [];
              final releve1 = pageReleves[j];
              final locataire1 = locataires.firstWhere((l) => l.id == releve1.locataireId);
              rowChildren.add(_buildReceipt(releve1, locataire1, configuration, cites)); // Pass cites here

              if (j + 1 < pageReleves.length) {
                final releve2 = pageReleves[j + 1];
                final locataire2 = locataires.firstWhere((l) => l.id == releve2.locataireId);
                rowChildren.add(_buildReceipt(releve2, locataire2, configuration, cites)); // Pass cites here
              } else {
                rowChildren.add(pw.SizedBox(width: receiptWidth, height: receiptHeight)); // Placeholder for empty slot
              }
              rows.add(pw.TableRow(children: rowChildren));
            }

            return [
              pw.Center(
                child: pw.Text(
                  'Rapport de consommation - $monthName $year',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Table(
                children: rows,
                columnWidths: {0: pw.FixedColumnWidth(receiptWidth), 1: pw.FixedColumnWidth(receiptWidth)},
              ),
            ];
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
