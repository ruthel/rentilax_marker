import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/unit_tarif.dart';
import '../models/unit_type.dart';
import '../services/tarif_service.dart';
import '../services/unit_service.dart';
import '../widgets/section_title.dart';
import '../utils/app_spacing.dart';

class TarifReportScreen extends StatefulWidget {
  const TarifReportScreen({super.key});

  @override
  State<TarifReportScreen> createState() => _TarifReportScreenState();
}

class _TarifReportScreenState extends State<TarifReportScreen> {
  final TarifService _tarifService = TarifService();
  final UnitService _unitService = UnitService();

  Map<String, dynamic>? _tarifStats;
  List<UnitTarif> _allTarifs = [];
  List<ConsumptionUnit> _availableUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportData();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _tarifService.getTarifStats();
      final allTarifs = await _tarifService.getAllTarifs();
      final units = await _unitService.getAllUnits();

      setState(() {
        _tarifStats = stats;
        _allTarifs = allTarifs;
        _availableUnits = units;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport de Tarification'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReportData,
            tooltip: 'Actualiser',
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareReport,
            tooltip: 'Partager',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReportData,
              child: SingleChildScrollView(
                padding: AppSpacing.page,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(text: 'Résumé', isMain: true),
                    _buildSummaryCard(),
                    const SizedBox(height: AppSpacing.md),
                    SectionTitle(text: 'Tarifs par type'),
                    _buildTarifsByTypeSection(),
                    const SizedBox(height: AppSpacing.md),
                    SectionTitle(text: 'Détail des tarifs'),
                    _buildDetailedTarifsList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSummaryCard() {
    if (_tarifStats == null) return const SizedBox.shrink();

    final stats = _tarifStats!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Résumé des Tarifs',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Unités avec tarif personnalisé',
                    '${stats['totalUnitsWithCustomTarifs']}',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Tarif moyen',
                    '${stats['averageTarif'].toStringAsFixed(2)} FCFA',
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Tarif minimum',
                    '${stats['minTarif'].toStringAsFixed(2)} FCFA',
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Tarif maximum',
                    '${stats['maxTarif'].toStringAsFixed(2)} FCFA',
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tarif de base: ${stats['defaultTarif'].toStringAsFixed(2)} FCFA',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTarifsByTypeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Tarifs par Type',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...UnitType.values.map((type) => _buildTypeTarifCard(type)),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeTarifCard(UnitType type) {
    final typeTarifs = _allTarifs.where((tarif) {
      // Récupérer l'unité pour déterminer son type
      final unit =
          _availableUnits.where((u) => u.id == tarif.unitId).firstOrNull;
      return unit?.type == type;
    }).toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getTypeName(type),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${typeTarifs.length} tarif(s)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (typeTarifs.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...typeTarifs.map((tarif) => _buildTarifItem(tarif)),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                'Aucun tarif personnalisé',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTarifItem(UnitTarif tarif) {
    final unit = _availableUnits.where((u) => u.id == tarif.unitId).firstOrNull;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              unit?.name ?? 'Unité inconnue',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          Text(
            '${tarif.tarif.toStringAsFixed(2)} ${tarif.devise}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedTarifsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.list_rounded,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Détail des Tarifs',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_allTarifs.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Aucun tarif personnalisé',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tous les relevés utilisent le tarif de base',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            else
              ..._allTarifs.map((tarif) => _buildDetailedTarifItem(tarif)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTarifItem(UnitTarif tarif) {
    final unit = _availableUnits.where((u) => u.id == tarif.unitId).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(unit?.type ?? UnitType.water)
              .withValues(alpha: 0.1),
          child: Icon(
            _getTypeIcon(unit?.type ?? UnitType.water),
            color: _getTypeColor(unit?.type ?? UnitType.water),
            size: 20,
          ),
        ),
        title: Text(
          unit?.name ?? 'Unité inconnue',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${unit?.symbol ?? ''} - ${unit?.fullName ?? ''}'),
            Text(
              'Créé le: ${DateFormat('dd/MM/yyyy').format(tarif.dateCreation)}',
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${tarif.tarif.toStringAsFixed(2)} ${tarif.devise}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            if (tarif.dateModification != null)
              Text(
                'Modifié le: ${DateFormat('dd/MM/yyyy').format(tarif.dateModification!)}',
                style: const TextStyle(fontSize: 10),
              ),
          ],
        ),
      ),
    );
  }

  void _shareReport() {
    // Implémentation du partage de rapport
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité de partage à implémenter')),
    );
  }

  Color _getTypeColor(UnitType type) {
    switch (type) {
      case UnitType.water:
        return Colors.blue;
      case UnitType.electricity:
        return Colors.orange;
      case UnitType.gas:
        return Colors.red;
    }
  }

  IconData _getTypeIcon(UnitType type) {
    switch (type) {
      case UnitType.water:
        return Icons.water_drop_rounded;
      case UnitType.electricity:
        return Icons.electrical_services_rounded;
      case UnitType.gas:
        return Icons.local_fire_department_rounded;
    }
  }

  String _getTypeName(UnitType type) {
    switch (type) {
      case UnitType.water:
        return 'Eau';
      case UnitType.electricity:
        return 'Électricité';
      case UnitType.gas:
        return 'Gaz';
    }
  }
}
