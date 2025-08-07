import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';

class LocataireHistoryScreen extends StatefulWidget {
  final Locataire locataire;

  const LocataireHistoryScreen({super.key, required this.locataire});

  @override
  State<LocataireHistoryScreen> createState() => _LocataireHistoryScreenState();
}

class _LocataireHistoryScreenState extends State<LocataireHistoryScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Releve> _releves = [];
  Configuration? _configuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final releves =
          await _databaseService.getRelevesByLocataire(widget.locataire.id!);
      // Sort relevés by moisReleve in ascending order for the chart
      releves.sort((a, b) => a.moisReleve.compareTo(b.moisReleve));
      final config = await _databaseService.getConfiguration();
      setState(() {
        _releves = releves;
        _configuration = config;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.errorLoadingHistory)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.historyOf(widget.locataire.nomComplet)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _releves.isEmpty
              ? Center(
                  child: Text(
                    localizations.noReadingsRecordedForThisTenant,
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        if (_releves.length > 1) ...[
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: AspectRatio(
                              aspectRatio: 1.70,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: true,
                                    getDrawingHorizontalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                    getDrawingVerticalLine: (value) {
                                      return const FlLine(
                                        color: Color(0xff37434d),
                                        strokeWidth: 1,
                                      );
                                    },
                                  ),
                                  titlesData: FlTitlesData(
                                    show: true,
                                    rightTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    topTitles: const AxisTitles(
                                        sideTitles:
                                            SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 30,
                                        getTitlesWidget: (value, meta) {
                                          final date = DateTime
                                              .fromMillisecondsSinceEpoch(
                                                  value.toInt());
                                          return SideTitleWidget(
                                            axisSide: meta.axisSide,
                                            child: Text(
                                                DateFormat('MMM yy', 'fr_FR')
                                                    .format(date),
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                          );
                                        },
                                      ),
                                    ),
                                    leftTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        reservedSize: 40,
                                        getTitlesWidget: (value, meta) {
                                          return Text(value.toInt().toString(),
                                              style: const TextStyle(
                                                  fontSize: 10));
                                        },
                                      ),
                                    ),
                                  ),
                                  borderData: FlBorderData(
                                    show: true,
                                    border: Border.all(
                                        color: const Color(0xff37434d),
                                        width: 1),
                                  ),
                                  minX: _releves
                                      .first.moisReleve.millisecondsSinceEpoch
                                      .toDouble(),
                                  maxX: _releves
                                      .last.moisReleve.millisecondsSinceEpoch
                                      .toDouble(),
                                  minY: 0,
                                  maxY: _releves
                                          .map((e) => e.consommation)
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.2, // 20% padding
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: _releves.map((releve) {
                                        return FlSpot(
                                            releve.moisReleve
                                                .millisecondsSinceEpoch
                                                .toDouble(),
                                            releve.consommation);
                                      }).toList(),
                                      isCurved: true,
                                      color: Colors.blue,
                                      barWidth: 5,
                                      isStrokeCapRound: true,
                                      dotData: const FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color:
                                            Colors.blue.withValues(alpha: 0.3),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const Divider(),
                        ],
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _releves.length,
                          itemBuilder: (context, index) {
                            final releve = _releves[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.assessment),
                                ),
                                title: Text(
                                  '${localizations.readingMonth}: ${DateFormat('MMMM yyyy', localizations.localeName).format(releve.moisReleve)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${localizations.creationDate}: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}'),
                                    Text(
                                        '${localizations.consumption}: ${releve.consommation.toStringAsFixed(2)} ${localizations.units}'),
                                    Text(
                                        '${localizations.amount}: ${releve.montant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}'),
                                    Row(
                                      children: [
                                        Text('${localizations.status}: '),
                                        Icon(
                                          releve.isPaid
                                              ? Icons.check_circle
                                              : Icons.cancel,
                                          color: releve.isPaid
                                              ? Colors.green
                                              : Colors.red,
                                          size: 16,
                                        ),
                                        Text(
                                          releve.isPaid
                                              ? ' ${localizations.paid}'
                                              : ' ${localizations.unpaid}',
                                          style: TextStyle(
                                            color: releve.isPaid
                                                ? Colors.green
                                                : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (releve.isPaid &&
                                            releve.paymentDate != null)
                                          Text(
                                              ' ${localizations.on} ${DateFormat('dd/MM/yyyy').format(releve.paymentDate!)}'),
                                      ],
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
