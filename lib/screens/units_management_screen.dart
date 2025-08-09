import 'package:flutter/material.dart';
import '../models/unit_type.dart';
import '../services/unit_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_input.dart';
import '../widgets/modern_list_tile.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_snackbar.dart';
import '../widgets/section_title.dart';
import '../utils/app_spacing.dart';

class UnitsManagementScreen extends StatefulWidget {
  const UnitsManagementScreen({super.key});

  @override
  State<UnitsManagementScreen> createState() => _UnitsManagementScreenState();
}

class _UnitsManagementScreenState extends State<UnitsManagementScreen>
    with SingleTickerProviderStateMixin {
  final UnitService _unitService = UnitService();
  late TabController _tabController;

  List<ConsumptionUnit> _waterUnits = [];
  List<ConsumptionUnit> _electricityUnits = [];
  List<ConsumptionUnit> _gasUnits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUnits();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUnits() async {
    setState(() => _isLoading = true);
    try {
      final waterUnits = await _unitService.getUnitsByType(UnitType.water);
      final electricityUnits =
          await _unitService.getUnitsByType(UnitType.electricity);
      final gasUnits = await _unitService.getUnitsByType(UnitType.gas);

      setState(() {
        _waterUnits = waterUnits;
        _electricityUnits = electricityUnits;
        _gasUnits = gasUnits;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ModernSnackBar.showError(
          context,
          'Erreur lors du chargement des unités: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Gestion des Unités',
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showAddUnitDialog(),
            tooltip: 'Ajouter une unité',
          ),
        ],
        bottom: ModernTabBar(
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
                _buildUnitsTab(UnitType.water, _waterUnits),
                _buildUnitsTab(UnitType.electricity, _electricityUnits),
                _buildUnitsTab(UnitType.gas, _gasUnits),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddUnitDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter une unité'),
      ),
    );
  }

  Widget _buildUnitsTab(UnitType type, List<ConsumptionUnit> units) {
    Theme.of(context);

    if (units.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadUnits,
      child: ListView.builder(
        padding: AppSpacing.page,
        itemCount: units.length + 1, // +1 pour les statistiques
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildStatsCard(type, units);
          }

          final unit = units[index - 1];
          return _buildUnitCard(unit);
        },
      ),
    );
  }

  Widget _buildStatsCard(UnitType type, List<ConsumptionUnit> units) {
    final theme = Theme.of(context);
    final defaultUnit = units.where((u) => u.isDefault).firstOrNull;

    return ModernCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getTypeColor(type).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getTypeIcon(type),
                  color: _getTypeColor(type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(text: type.name),
                    Text(
                      '${units.length} unité${units.length > 1 ? 's' : ''} disponible${units.length > 1 ? 's' : ''}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (defaultUnit != null) ...[
            SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unité par défaut: ${defaultUnit.name} (${defaultUnit.symbol})',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUnitCard(ConsumptionUnit unit) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return ModernListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getTypeColor(unit.type).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          unit.symbol,
          style: theme.textTheme.titleMedium?.copyWith(
            color: _getTypeColor(unit.type),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: unit.name,
      subtitle:
          '${unit.fullName}\nFacteur de conversion: ${unit.conversionFactor}',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (unit.isDefault)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Défaut',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () => _showUnitOptions(unit),
    );
  }

  Widget _buildEmptyState(UnitType type) {
    final theme = Theme.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getTypeColor(type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                _getTypeIcon(type),
                size: 64,
                color: _getTypeColor(type),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SectionTitle(text: 'Aucune unité ${type.name.toLowerCase()}'),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Ajoutez votre première unité de mesure pour ${type.name.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppSpacing.lg),
            ModernButton(
              text: 'Ajouter une unité',
              icon: Icons.add_rounded,
              onPressed: () => _showAddUnitDialog(type),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitOptions(ConsumptionUnit unit) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            SectionTitle(text: unit.name),
            SizedBox(height: AppSpacing.md),
            if (!unit.isDefault)
              ModernListTile(
                leading: const Icon(Icons.star_rounded),
                title: 'Définir comme défaut',
                onTap: () async {
                  Navigator.pop(context);
                  await _setAsDefault(unit);
                },
              ),
            ModernListTile(
              leading: const Icon(Icons.edit_rounded),
              title: 'Modifier',
              onTap: () {
                Navigator.pop(context);
                _showAddUnitDialog(unit.type, unit);
              },
            ),
            FutureBuilder<bool>(
              future: _unitService.canDeleteUnit(unit.id!),
              builder: (context, snapshot) {
                final canDelete = snapshot.data ?? false;
                return ModernListTile(
                  leading: Icon(
                    Icons.delete_rounded,
                    color: canDelete
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.5),
                  ),
                  title: 'Supprimer',
                  enabled: canDelete,
                  onTap: canDelete
                      ? () {
                          Navigator.pop(context);
                          _confirmDeleteUnit(unit);
                        }
                      : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddUnitDialog([UnitType? type, ConsumptionUnit? unit]) {
    final nameController = TextEditingController(text: unit?.name ?? '');
    final symbolController = TextEditingController(text: unit?.symbol ?? '');
    final fullNameController =
        TextEditingController(text: unit?.fullName ?? '');
    final conversionController = TextEditingController(
      text: unit?.conversionFactor.toString() ?? '1.0',
    );

    UnitType selectedType = type ?? unit?.type ?? UnitType.water;
    bool isDefault = unit?.isDefault ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(unit == null ? 'Ajouter une unité' : 'Modifier l\'unité'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<UnitType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Type d\'unité',
                    border: OutlineInputBorder(),
                  ),
                  items: UnitType.values
                      .map((type) => DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getTypeIcon(type), size: 20),
                                const SizedBox(width: 8),
                                Text(type.name),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: unit == null
                      ? (value) {
                          if (value != null) {
                            setDialogState(() => selectedType = value);
                          }
                        }
                      : null, // Ne pas permettre de changer le type lors de la modification
                ),
                SizedBox(height: AppSpacing.md),
                ModernInput(
                  label: 'Nom de l\'unité *',
                  controller: nameController,
                ),
                SizedBox(height: AppSpacing.md),
                ModernInput(
                  label: 'Symbole *',
                  controller: symbolController,
                ),
                SizedBox(height: AppSpacing.md),
                ModernInput(
                  label: 'Nom complet *',
                  controller: fullNameController,
                ),
                SizedBox(height: AppSpacing.md),
                ModernInput(
                  label: 'Facteur de conversion',
                  helperText: 'Facteur de conversion vers l\'unité de base',
                  controller: conversionController,
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  title: const Text('Unité par défaut'),
                  subtitle: const Text(
                      'Cette unité sera utilisée par défaut pour ce type'),
                  value: isDefault,
                  onChanged: (value) {
                    setDialogState(() => isDefault = value ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            ModernButton(
              text: 'Annuler',
              type: ModernButtonType.ghost,
              onPressed: () => Navigator.pop(context),
            ),
            ModernButton(
              text: unit == null ? 'Ajouter' : 'Modifier',
              onPressed: () => _saveUnit(
                unit,
                selectedType,
                nameController.text,
                symbolController.text,
                fullNameController.text,
                conversionController.text,
                isDefault,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveUnit(
    ConsumptionUnit? existingUnit,
    UnitType type,
    String name,
    String symbol,
    String fullName,
    String conversionFactorStr,
    bool isDefault,
  ) async {
    if (name.trim().isEmpty ||
        symbol.trim().isEmpty ||
        fullName.trim().isEmpty) {
      ModernSnackBar.showError(
        context,
        'Veuillez remplir tous les champs obligatoires',
      );
      return;
    }

    final conversionFactor = double.tryParse(conversionFactorStr);
    if (conversionFactor == null || conversionFactor <= 0) {
      ModernSnackBar.showError(
        context,
        'Le facteur de conversion doit être un nombre positif',
      );
      return;
    }

    try {
      final unit = ConsumptionUnit(
        id: existingUnit?.id,
        name: name.trim(),
        symbol: symbol.trim(),
        fullName: fullName.trim(),
        type: type,
        conversionFactor: conversionFactor,
        isDefault: isDefault,
      );

      if (existingUnit == null) {
        await _unitService.addUnit(unit);
      } else {
        await _unitService.updateUnit(unit);
      }

      if (isDefault) {
        await _unitService.setAsDefault(unit.id!);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadUnits();

      ModernSnackBar.showSuccess(
        context,
        existingUnit == null
            ? 'Unité ajoutée avec succès'
            : 'Unité modifiée avec succès',
      );
    } catch (e) {
      if (!mounted) return;
      ModernSnackBar.showError(
        context,
        'Erreur lors de la sauvegarde: $e',
      );
    }
  }

  Future<void> _setAsDefault(ConsumptionUnit unit) async {
    try {
      await _unitService.setAsDefault(unit.id!);
      _loadUnits();
      ModernSnackBar.showSuccess(
        context,
        '${unit.name} définie comme unité par défaut',
      );
    } catch (e) {
      ModernSnackBar.showError(
        context,
        'Erreur lors de la définition par défaut: $e',
      );
    }
  }

  void _confirmDeleteUnit(ConsumptionUnit unit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'unité "${unit.name}" ?'),
        actions: [
          ModernButton(
            text: 'Annuler',
            type: ModernButtonType.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: 'Supprimer',
            type: ModernButtonType.danger,
            onPressed: () => _deleteUnit(unit),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUnit(ConsumptionUnit unit) async {
    try {
      await _unitService.deleteUnit(unit.id!);
      if (!mounted) return;
      Navigator.pop(context);
      _loadUnits();
      ModernSnackBar.showSuccess(
        context,
        'Unité supprimée avec succès',
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ModernSnackBar.showError(
        context,
        'Erreur lors de la suppression: $e',
      );
    }
  }

  Color _getTypeColor(UnitType type) {
    switch (type) {
      case UnitType.water:
        return Colors.blue;
      case UnitType.electricity:
        return Colors.amber;
      case UnitType.gas:
        return Colors.orange;
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
}
