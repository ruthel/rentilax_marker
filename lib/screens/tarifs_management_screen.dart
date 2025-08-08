import 'package:flutter/material.dart';
import '../models/unit_tarif.dart';
import '../models/unit_type.dart';
import '../services/tarif_service.dart';
import '../services/unit_service.dart';

class TarifsManagementScreen extends StatefulWidget {
  const TarifsManagementScreen({super.key});

  @override
  State<TarifsManagementScreen> createState() => _TarifsManagementScreenState();
}

class _TarifsManagementScreenState extends State<TarifsManagementScreen>
    with SingleTickerProviderStateMixin {
  final TarifService _tarifService = TarifService();
  final UnitService _unitService = UnitService();
  late TabController _tabController;

  List<ConsumptionUnit> _waterUnits = [];
  List<ConsumptionUnit> _electricityUnits = [];
  List<ConsumptionUnit> _gasUnits = [];
  Map<int, UnitTarif?> _unitTarifs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final waterUnits = await _unitService.getUnitsByType(UnitType.water);
      final electricityUnits =
          await _unitService.getUnitsByType(UnitType.electricity);
      final gasUnits = await _unitService.getUnitsByType(UnitType.gas);

      // Charger les tarifs pour toutes les unités
      final allUnits = [...waterUnits, ...electricityUnits, ...gasUnits];
      final unitTarifs = <int, UnitTarif?>{};

      for (final unit in allUnits) {
        final tarif = await _tarifService.getTarifForUnit(unit.id!);
        unitTarifs[unit.id!] = tarif;
      }

      setState(() {
        _waterUnits = waterUnits;
        _electricityUnits = electricityUnits;
        _gasUnits = gasUnits;
        _unitTarifs = unitTarifs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des données: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Tarifs'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Eau', icon: Icon(Icons.water_drop_rounded)),
            Tab(
                text: 'Électricité',
                icon: Icon(Icons.electrical_services_rounded)),
            Tab(text: 'Gaz', icon: Icon(Icons.local_fire_department_rounded)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTarifsTab(UnitType.water, _waterUnits),
                _buildTarifsTab(UnitType.electricity, _electricityUnits),
                _buildTarifsTab(UnitType.gas, _gasUnits),
              ],
            ),
    );
  }

  Widget _buildTarifsTab(UnitType type, List<ConsumptionUnit> units) {
    if (units.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: units.length + 1, // +1 pour les statistiques
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsCard(type, units);
          }

          final unit = units[index - 1];
          final tarif = _unitTarifs[unit.id];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getTypeColor(type).withOpacity(0.1),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                ),
              ),
              title: Text(
                unit.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Symbole: ${unit.symbol}'),
                  const SizedBox(height: 4),
                  Text(
                    tarif != null
                        ? 'Tarif: ${_tarifService.formatTarif(tarif.tarif, tarif.devise)}'
                        : 'Tarif: Utilise le tarif de base',
                    style: TextStyle(
                      color: tarif != null ? Colors.green : Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit_rounded),
                        const SizedBox(width: 8),
                        Text(tarif != null
                            ? 'Modifier le tarif'
                            : 'Définir un tarif'),
                      ],
                    ),
                  ),
                  if (tarif != null)
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          const Icon(Icons.delete_rounded, color: Colors.red),
                          const SizedBox(width: 8),
                          const Text('Supprimer le tarif',
                              style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'history',
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded),
                        const SizedBox(width: 8),
                        const Text('Historique'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'edit') {
                    _showTarifDialog(unit, tarif);
                  } else if (value == 'delete') {
                    _confirmDeleteTarif(unit, tarif!);
                  } else if (value == 'history') {
                    _showTarifHistory(unit);
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(UnitType type, List<ConsumptionUnit> units) {
    final unitsWithTarifs =
        units.where((unit) => _unitTarifs[unit.id] != null).length;
    final totalUnits = units.length;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Statistiques ${_getTypeName(type)}',
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
                    '$unitsWithTarifs / $totalUnits',
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatItem(
                    'Unités avec tarif par défaut',
                    '${totalUnits - unitsWithTarifs}',
                    Colors.blue,
                  ),
                ),
              ],
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
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(UnitType type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getTypeIcon(type),
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune unité ${_getTypeName(type).toLowerCase()}',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des unités dans la gestion des unités',
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  void _showTarifDialog(ConsumptionUnit unit, UnitTarif? existingTarif) {
    final tarifController = TextEditingController(
      text: existingTarif?.tarif.toString() ?? '',
    );
    final deviseController = TextEditingController(
      text: existingTarif?.devise ?? 'FCFA',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: Text(existingTarif == null
            ? 'Définir un tarif pour ${unit.name}'
            : 'Modifier le tarif de ${unit.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: tarifController,
              decoration: const InputDecoration(
                labelText: 'Tarif *',
                hintText: 'Ex: 150.0',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deviseController,
              decoration: const InputDecoration(
                labelText: 'Devise',
                hintText: 'Ex: FCFA',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.currency_exchange_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Colors.blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ce tarif sera utilisé pour tous les relevés utilisant l\'unité ${unit.symbol}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _saveTarif(unit, existingTarif,
                tarifController.text, deviseController.text),
            child: Text(existingTarif == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveTarif(
    ConsumptionUnit unit,
    UnitTarif? existingTarif,
    String tarifStr,
    String devise,
  ) async {
    if (tarifStr.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir un tarif')),
      );
      return;
    }

    final tarif = double.tryParse(tarifStr.trim());
    if (tarif == null || tarif <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le tarif doit être un nombre positif')),
      );
      return;
    }

    try {
      final newTarif = UnitTarif(
        id: existingTarif?.id,
        unitId: unit.id!,
        tarif: tarif,
        devise: devise.trim().isEmpty ? 'FCFA' : devise.trim(),
      );

      if (existingTarif == null) {
        await _tarifService.addTarif(newTarif);
      } else {
        await _tarifService.updateTarif(newTarif);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(existingTarif == null
                ? 'Tarif ajouté avec succès'
                : 'Tarif modifié avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  void _confirmDeleteTarif(ConsumptionUnit unit, UnitTarif tarif) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: const EdgeInsets.all(16),
        title: const Text('Confirmer la suppression'),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer le tarif de ${unit.name} ?\n\n'
          'Tarif actuel: ${_tarifService.formatTarif(tarif.tarif, tarif.devise)}\n\n'
          'Après suppression, l\'unité utilisera le tarif de base.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteTarif(unit, tarif),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:
                const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTarif(ConsumptionUnit unit, UnitTarif tarif) async {
    try {
      await _tarifService.deleteTarif(tarif.id!);
      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarif supprimé avec succès')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }

  void _showTarifHistory(ConsumptionUnit unit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TarifHistoryScreen(unit: unit),
      ),
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

class TarifHistoryScreen extends StatefulWidget {
  final ConsumptionUnit unit;

  const TarifHistoryScreen({super.key, required this.unit});

  @override
  State<TarifHistoryScreen> createState() => _TarifHistoryScreenState();
}

class _TarifHistoryScreenState extends State<TarifHistoryScreen> {
  final TarifService _tarifService = TarifService();
  List<UnitTarif> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final history =
          await _tarifService.getTarifHistoryForUnit(widget.unit.id!);
      setState(() {
        _history = history;
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
        title: const Text('Historique des tarifs'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun historique',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final tarif = _history[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tarif.isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          child: Icon(
                            tarif.isActive
                                ? Icons.check_rounded
                                : Icons.history_rounded,
                            color: tarif.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        title: Text(
                          _tarifService.formatTarif(tarif.tarif, tarif.devise),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: tarif.isActive ? Colors.green : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tarif.isActive ? 'Tarif actuel' : 'Ancien tarif',
                              style: TextStyle(
                                color:
                                    tarif.isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            Text(
                              'Créé le: ${_formatDate(tarif.dateCreation)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            if (tarif.dateModification != null)
                              Text(
                                'Modifié le: ${_formatDate(tarif.dateModification!)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
