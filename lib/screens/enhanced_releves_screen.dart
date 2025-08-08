import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import 'package:rentilax_tracker/models/unit_type.dart';
import 'package:rentilax_tracker/services/tarif_service.dart';
import 'package:rentilax_tracker/services/unit_service.dart';
import '../models/cite.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';

import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_search_bar.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/enhanced_snackbar.dart';

import 'payment_management_screen.dart';

class EnhancedRelevesScreen extends StatefulWidget {
  const EnhancedRelevesScreen({super.key});

  @override
  State<EnhancedRelevesScreen> createState() => _EnhancedRelevesScreenState();
}

class _EnhancedRelevesScreenState extends State<EnhancedRelevesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final UnitService _unitService = UnitService();
  final TarifService _tarifService = TarifService();

  List<Releve> _allReleves = [];
  List<Releve> _filteredReleves = [];
  List<Locataire> _locataires = [];
  List<Cite> _cites = [];
  List<ConsumptionUnit> _availableUnits = [];

  Configuration? _configuration;
  bool _isLoading = true;
  String _searchQuery = '';
  Map<String, dynamic> _activeFilters = {};

  // Animation controllers
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadData();
  }

  void _setupAnimations() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final releves = await _databaseService.getReleves();
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();
      final units = await _unitService.getAllUnits();

      setState(() {
        _allReleves = releves;
        _filteredReleves = releves;
        _locataires = locataires;
        _cites = cites;
        _configuration = config;
        _availableUnits = units;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        EnhancedSnackBar.showError(
          context: context,
          message: 'Erreur lors du chargement: $e',
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredReleves = _allReleves.where((releve) {
        // Filtre de recherche
        if (_searchQuery.isNotEmpty) {
          final locataire = _locataires.firstWhere(
            (l) => l.id == releve.locataireId,
            orElse: () => Locataire(
                nom: '',
                prenom: '',
                citeId: 0,
                numeroLogement: '',
                dateEntree: DateTime.now()),
          );
          final query = _searchQuery.toLowerCase();
          final matchesName = '${locataire.prenom} ${locataire.nom}'
              .toLowerCase()
              .contains(query);
          final matchesLogement =
              locataire.numeroLogement.toLowerCase().contains(query);
          final matchesComment =
              releve.commentaire?.toLowerCase().contains(query) ?? false;
          if (!matchesName && !matchesLogement && !matchesComment) return false;
        }

        // Filtre par statut de paiement
        if (_activeFilters['payment_status'] != null) {
          if (_activeFilters['payment_status'] == 'paid' && !releve.isPaid)
            return false;
          if (_activeFilters['payment_status'] == 'unpaid' && releve.isPaid)
            return false;
          if (_activeFilters['payment_status'] == 'partial' &&
              !releve.isPartiallyPaid) return false;
        }

        // Filtre par cité
        if (_activeFilters['cite_id'] != null) {
          final locataire = _locataires.firstWhere(
            (l) => l.id == releve.locataireId,
            orElse: () => Locataire(
                nom: '',
                prenom: '',
                citeId: 0,
                numeroLogement: '',
                dateEntree: DateTime.now()),
          );
          if (locataire.citeId != _activeFilters['cite_id']) return false;
        }

        // Filtre par mois
        if (_activeFilters['month_start'] != null) {
          final startDate = _activeFilters['month_start'] as DateTime;
          if (releve.moisReleve.isBefore(startDate)) return false;
        }

        if (_activeFilters['month_end'] != null) {
          final endDate = _activeFilters['month_end'] as DateTime;
          if (releve.moisReleve.isAfter(endDate)) return false;
        }

        // Filtre par montant
        if (_activeFilters['amount_min'] != null) {
          if (releve.montant < _activeFilters['amount_min']) return false;
        }

        if (_activeFilters['amount_max'] != null) {
          if (releve.montant > _activeFilters['amount_max']) return false;
        }

        return true;
      }).toList();

      // Tri
      if (_activeFilters['sort'] == 'date_asc') {
        _filteredReleves.sort((a, b) => a.dateReleve.compareTo(b.dateReleve));
      } else if (_activeFilters['sort'] == 'date_desc') {
        _filteredReleves.sort((a, b) => b.dateReleve.compareTo(a.dateReleve));
      } else if (_activeFilters['sort'] == 'amount_asc') {
        _filteredReleves.sort((a, b) => a.montant.compareTo(b.montant));
      } else if (_activeFilters['sort'] == 'amount_desc') {
        _filteredReleves.sort((a, b) => b.montant.compareTo(a.montant));
      } else if (_activeFilters['sort'] == 'consumption_asc') {
        _filteredReleves
            .sort((a, b) => a.consommation.compareTo(b.consommation));
      } else if (_activeFilters['sort'] == 'consumption_desc') {
        _filteredReleves
            .sort((a, b) => b.consommation.compareTo(a.consommation));
      }
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _showFilters() {
    final filterOptions = [
      FilterOption(
        key: 'sort',
        label: 'Trier par',
        type: FilterType.radio,
        values: const [
          FilterValue(key: 'date_desc', label: 'Date (Plus récent)'),
          FilterValue(key: 'date_asc', label: 'Date (Plus ancien)'),
          FilterValue(key: 'amount_desc', label: 'Montant (Plus élevé)'),
          FilterValue(key: 'amount_asc', label: 'Montant (Plus bas)'),
          FilterValue(
              key: 'consumption_desc', label: 'Consommation (Plus élevée)'),
          FilterValue(
              key: 'consumption_asc', label: 'Consommation (Plus basse)'),
        ],
      ),
      const FilterOption(
        key: 'payment_status',
        label: 'Statut de paiement',
        type: FilterType.radio,
        values: [
          FilterValue(key: '', label: 'Tous'),
          FilterValue(key: 'paid', label: 'Payé'),
          FilterValue(key: 'unpaid', label: 'Non payé'),
          FilterValue(key: 'partial', label: 'Partiellement payé'),
        ],
      ),
      FilterOption(
        key: 'cite_id',
        label: 'Cité',
        type: FilterType.radio,
        values: [
          const FilterValue(key: '', label: 'Toutes les cités'),
          ..._cites.map((cite) => FilterValue(
                key: cite.id.toString(),
                label: cite.nom,
              )),
        ],
      ),
      const FilterOption(
        key: 'month',
        label: 'Période de relevé',
        type: FilterType.dateRange,
      ),
      FilterOption(
        key: 'amount',
        label: 'Montant (FCFA)',
        type: FilterType.range,
        min: 0,
        max: _allReleves.isEmpty
            ? 100000
            : _allReleves
                .map((r) => r.montant)
                .reduce((a, b) => a > b ? a : b)
                .ceil(),
        divisions: 20,
      ),
    ];

    showFilterBottomSheet(
      context: context,
      title: 'Filtrer les relevés',
      options: filterOptions,
      currentFilters: _activeFilters,
      onApplyFilters: (filters) {
        setState(() {
          _activeFilters = filters;
          // Convertir les IDs de cité en int
          if (filters['cite_id'] != null &&
              filters['cite_id'].toString().isNotEmpty) {
            _activeFilters['cite_id'] =
                int.tryParse(filters['cite_id'].toString());
          } else {
            _activeFilters.remove('cite_id');
          }
        });
        _applyFilters();
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_activeFilters['sort'] != null) count++;
    if (_activeFilters['payment_status'] != null) count++;
    if (_activeFilters['cite_id'] != null) count++;
    if (_activeFilters['month_start'] != null ||
        _activeFilters['month_end'] != null) count++;
    if (_activeFilters['amount_min'] != null ||
        _activeFilters['amount_max'] != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.relevesScreenTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showFilters,
            tooltip: 'Trier et filtrer',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche améliorée
          EnhancedSearchBar(
            hintText: 'Rechercher un relevé...',
            onChanged: _onSearchChanged,
            showFilters: true,
            onFilterTap: _showFilters,
            filterCount: _activeFilterCount,
          ),

          // Statistiques rapides
          if (!_isLoading && _allReleves.isNotEmpty) _buildStatsSection(),

          // Liste des relevés
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReleves.isEmpty
                    ? _buildEmptyState(localizations)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filteredReleves.length,
                          itemBuilder: (context, index) {
                            final releve = _filteredReleves[index];
                            return AnimatedListItem(
                              index: index,
                              child:
                                  _buildModernReleveCard(releve, localizations),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _fabScaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabScaleAnimation.value,
            child: FloatingActionButton.extended(
              onPressed: () {
                _fabAnimationController.forward().then((_) {
                  _fabAnimationController.reverse();
                });
                _showReleveDialog();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau relevé'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSection() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final totalReleves = _allReleves.length;

    final relevesPaid = _allReleves.where((r) => r.isPaid).length;
    final relevesUnpaid = _allReleves.where((r) => !r.isPaid).length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            context,
            'Total',
            '$totalReleves',
            Icons.assessment_rounded,
          ),
          _buildStatItem(
            context,
            'Affichés',
            '${_filteredReleves.length}',
            Icons.visibility_rounded,
          ),
          _buildStatItem(
            context,
            'Payés',
            '$relevesPaid',
            Icons.check_circle_rounded,
          ),
          _buildStatItem(
            context,
            'Non payés',
            '$relevesUnpaid',
            Icons.pending_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Icon(
          icon,
          color: colorScheme.primary,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.assessment_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Aucun relevé trouvé'
                : localizations.noRelevesFound,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Essayez de modifier vos critères de recherche'
                : 'Commencez par ajouter votre premier relevé',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _activeFilters.isNotEmpty) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _activeFilters.clear();
                });
                _applyFilters();
              },
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Effacer les filtres'),
            ),
          ] else ...[
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _showReleveDialog(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouveau relevé'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernReleveCard(Releve releve, dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final locataire = _getLocataire(releve.locataireId);
    final citeNom = _getCiteNom(locataire.citeId);

    return EnhancedListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _getStatusColor(releve).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          _getStatusIcon(releve),
          color: _getStatusColor(releve),
          size: 24,
        ),
      ),
      title: Text('${locataire.prenom} ${locataire.nom}'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_city_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                '$citeNom - Logement ${locataire.numeroLogement}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMMM yyyy', 'fr_FR').format(releve.moisReleve),
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.water_drop_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Consommation: ${releve.consommation.toStringAsFixed(1)} ${_getUnitSymbol(releve)}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(releve).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${releve.montant.toStringAsFixed(0)} ${_configuration?.devise ?? 'FCFA'}',
                  style: TextStyle(
                    color: _getStatusColor(releve),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(releve).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getStatusText(releve, localizations),
                  style: TextStyle(
                    color: _getStatusColor(releve),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert_rounded,
          color: colorScheme.onSurfaceVariant,
        ),
        itemBuilder: (context) => [
          if (!releve.isPaid || releve.remainingAmount > 0)
            PopupMenuItem(
              value: 'manage_payment',
              child: Row(
                children: [
                  Icon(Icons.payment_rounded, size: 18, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(releve.isPartiallyPaid
                      ? 'Compléter paiement'
                      : 'Gérer paiement'),
                ],
              ),
            ),
          PopupMenuItem(
            value: 'toggle_payment',
            child: Row(
              children: [
                Icon(
                  releve.isPaid
                      ? Icons.cancel_outlined
                      : Icons.check_circle_outline,
                  size: 18,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(releve.isPaid
                    ? localizations.markAsUnpaid
                    : localizations.markAsPaid),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'view',
            child: Row(
              children: [
                Icon(Icons.visibility_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(localizations.viewDetails),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit_rounded, size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(localizations.modify),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  localizations.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'manage_payment') {
            _navigateToPaymentManagement(releve);
          } else if (value == 'toggle_payment') {
            _togglePaymentStatus(releve);
          } else if (value == 'view') {
            _showReleveDetails(releve);
          } else if (value == 'edit') {
            _showReleveDialog(releve);
          } else if (value == 'delete') {
            _confirmDelete(releve);
          }
        },
      ),
      onTap: () => _showReleveDetails(releve),
    );
  }

  Locataire _getLocataire(int locataireId) {
    return _locataires.firstWhere(
      (l) => l.id == locataireId,
      orElse: () => Locataire(
        nom: 'Inconnu',
        prenom: '',
        citeId: 0,
        numeroLogement: '',
        dateEntree: DateTime.now(),
      ),
    );
  }

  String _getCiteNom(int citeId) {
    final cite = _cites.firstWhere(
      (c) => c.id == citeId,
      orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
    );
    return cite.nom;
  }

  Color _getStatusColor(Releve releve) {
    if (releve.isPaid) return Colors.green;
    if (releve.isPartiallyPaid) return Colors.orange;
    return Colors.red;
  }

  IconData _getStatusIcon(Releve releve) {
    if (releve.isPaid) return Icons.check_circle_rounded;
    if (releve.isPartiallyPaid) return Icons.pending_rounded;
    return Icons.cancel_rounded;
  }

  String _getStatusText(Releve releve, dynamic localizations) {
    if (releve.isPaid) return localizations.paid;
    if (releve.isPartiallyPaid) return 'Partiel';
    return localizations.unpaid;
  }

  String _getUnitSymbol(Releve releve) {
    switch (releve.unitType) {
      case UnitType.water:
        return 'm³';
      case UnitType.electricity:
        return 'kWh';
      case UnitType.gas:
        return 'm³';
    }
  }

  // Méthode helper pour récupérer le tarif à afficher
  Future<double> _getTarifForDisplay(
      int locataireId, ConsumptionUnit? selectedUnit) async {
    final locataire = _locataires.firstWhere((l) => l.id == locataireId);

    if (locataire.tarifPersonnalise != null) {
      return locataire.tarifPersonnalise!;
    } else if (selectedUnit != null) {
      return await _tarifService.getEffectiveTarifForUnit(selectedUnit.id!);
    } else {
      return _configuration?.tarifBase ?? 0.0;
    }
  }

  Color _getUnitTypeColor(UnitType type) {
    switch (type) {
      case UnitType.water:
        return Colors.blue;
      case UnitType.electricity:
        return Colors.amber;
      case UnitType.gas:
        return Colors.orange;
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

  Future<void> _saveReleve(
    Releve? existingReleve,
    int locataireId,
    String ancienIndex,
    String nouvelIndex,
    DateTime dateReleve,
    DateTime moisReleve,
    String commentaire,
    ConsumptionUnit? selectedUnit,
  ) async {
    final localizations = context.l10n;
    if (ancienIndex.trim().isEmpty || nouvelIndex.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.indexesRequired)),
      );
      return;
    }

    final double? ancienIndexValue = double.tryParse(ancienIndex.trim());
    final double? nouvelIndexValue = double.tryParse(nouvelIndex.trim());

    if (ancienIndexValue == null || nouvelIndexValue == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.indexesMustBeValidNumbers)),
      );
      return;
    }

    if (nouvelIndexValue <= ancienIndexValue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.newIndexGreaterThanOldIndex)),
      );
      return;
    }

    try {
      // Déterminer le tarif à utiliser selon la hiérarchie :
      // 1. Tarif personnalisé du locataire
      // 2. Tarif spécifique de l'unité
      // 3. Tarif de base de la configuration
      final locataire = _locataires.firstWhere((l) => l.id == locataireId);
      double tarif;

      if (locataire.tarifPersonnalise != null) {
        // Priorité 1: Tarif personnalisé du locataire
        tarif = locataire.tarifPersonnalise!;
      } else if (selectedUnit != null) {
        // Priorité 2: Tarif spécifique de l'unité
        tarif = await _tarifService.getEffectiveTarifForUnit(selectedUnit.id!);
      } else {
        // Priorité 3: Tarif de base de la configuration
        tarif = _configuration!.tarifBase;
      }

      if (existingReleve == null) {
        // Vérifier si un relevé existe déjà pour ce locataire et ce mois de relevé
        final existingMonthlyReleve =
            await _databaseService.getReleveForLocataireAndMonth(
          locataireId,
          moisReleve.month,
          moisReleve.year,
        );
        if (existingMonthlyReleve != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(localizations.readingAlreadyExists(
                    DateFormat.MMMM('fr_FR').format(moisReleve)))),
          );
          return;
        }

        // Ajouter nouveau relevé
        final nouveauReleve = Releve(
          locataireId: locataireId,
          ancienIndex: ancienIndexValue,
          nouvelIndex: nouvelIndexValue,
          tarif: tarif,
          dateReleve: dateReleve,
          moisReleve: moisReleve,
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
          unitId: selectedUnit?.id,
          unitType: selectedUnit?.type ?? UnitType.water,
        );
        await _databaseService.insertReleve(nouveauReleve);
      } else {
        // Vérifier si le nouveau mois de relevé n'entre pas en conflit (sauf si c'est le même relevé)
        if (existingReleve.moisReleve.month != moisReleve.month ||
            existingReleve.moisReleve.year != moisReleve.year) {
          final conflictReleve =
              await _databaseService.getReleveForLocataireAndMonth(
            locataireId,
            moisReleve.month,
            moisReleve.year,
          );
          if (conflictReleve != null &&
              conflictReleve.id != existingReleve.id) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(localizations.readingAlreadyExists(
                      DateFormat.MMMM('fr_FR').format(moisReleve)))),
            );
            return;
          }
        }

        // Modifier relevé existant
        final releveModifie = Releve(
          id: existingReleve.id,
          locataireId: locataireId,
          ancienIndex: ancienIndexValue,
          nouvelIndex: nouvelIndexValue,
          tarif: tarif,
          dateReleve: dateReleve,
          moisReleve: moisReleve,
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
          isPaid: existingReleve.isPaid, // Conserver le statut de paiement
          paymentDate:
              existingReleve.paymentDate, // Conserver la date de paiement
          paidAmount: existingReleve.paidAmount, // Conserver le montant payé
          unitId: selectedUnit?.id,
          unitType: selectedUnit?.type ?? existingReleve.unitType,
        );
        await _databaseService.updateReleve(releveModifie);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingReleve == null
              ? localizations.readingAddedSuccessfully
              : localizations.readingModifiedSuccessfully),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorSavingReading}: $e')),
      );
    }
  }

  void _showReleveDialog([Releve? releve]) async {
    final localizations = context.l10n;
    if (_locataires.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.locataireRequired)),
      );
      return;
    }

    final ancienIndexController =
        TextEditingController(text: releve?.ancienIndex.toString() ?? '');
    final nouvelIndexController =
        TextEditingController(text: releve?.nouvelIndex.toString() ?? '');
    final commentaireController =
        TextEditingController(text: releve?.commentaire ?? '');

    int selectedLocataireId = releve?.locataireId ?? _locataires.first.id!;
    DateTime selectedDate = releve?.dateReleve ?? DateTime.now();
    DateTime selectedMoisReleve = releve?.moisReleve ?? DateTime.now();

    // Sélection d'unité
    ConsumptionUnit? selectedUnit;
    if (releve?.unitId != null) {
      selectedUnit = await _unitService.getUnitById(releve!.unitId!);
    } else {
      // Utiliser l'unité par défaut selon la configuration
      selectedUnit = await _unitService.getDefaultUnitForType(
          _configuration?.defaultUnitType ?? UnitType.water);
    }

    // Si c'est un nouveau relevé, récupérer le dernier index du locataire
    if (releve == null) {
      final dernierReleve =
          await _databaseService.getDernierReleve(selectedLocataireId);
      if (dernierReleve != null) {
        ancienIndexController.text = dernierReleve.nouvelIndex.toString();
      } else {
        // Si aucun relevé précédent, initialiser à 0
        ancienIndexController.text = '0';
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(releve == null
              ? localizations.newReading
              : localizations.modifyReading),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: double.maxFinite,
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: IntrinsicHeight(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedLocataireId,
                      decoration: InputDecoration(
                        labelText: '${localizations.tenant} *',
                        border: const OutlineInputBorder(),
                      ),
                      items: _locataires
                          .map((locataire) => DropdownMenuItem(
                                value: locataire.id,
                                child: Text(locataire.nomComplet),
                              ))
                          .toList(),
                      onChanged: releve == null
                          ? (value) async {
                              if (value != null) {
                                setDialogState(
                                    () => selectedLocataireId = value);
                                // Récupérer le dernier index pour ce locataire
                                final dernierReleve = await _databaseService
                                    .getDernierReleve(value);
                                if (dernierReleve != null) {
                                  ancienIndexController.text =
                                      dernierReleve.nouvelIndex.toString();
                                } else {
                                  ancienIndexController.text = '0';
                                }
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ancienIndexController,
                      decoration: InputDecoration(
                        labelText: '${localizations.oldIndex} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nouvelIndexController,
                      decoration: InputDecoration(
                        labelText: '${localizations.newIndex} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ConsumptionUnit>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unité de mesure *',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUnits
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text('${unit.name} (${unit.symbol})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedUnit = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    // Affichage du tarif qui sera utilisé
                    FutureBuilder<double>(
                      future: _getTarifForDisplay(
                          selectedLocataireId, selectedUnit),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        final tarif = snapshot.data ?? 0.0;
                        final locataire = _locataires
                            .firstWhere((l) => l.id == selectedLocataireId);
                        String tarifSource = '';
                        Color tarifColor = Colors.grey;

                        if (locataire.tarifPersonnalise != null) {
                          tarifSource = 'Tarif personnalisé du locataire';
                          tarifColor = Colors.orange;
                        } else if (selectedUnit != null) {
                          tarifSource =
                              'Tarif de l\'unité ${selectedUnit!.symbol}';
                          tarifColor = Colors.blue;
                        } else {
                          tarifSource = 'Tarif de base';
                          tarifColor = Colors.grey;
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: tarifColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: tarifColor.withValues(alpha: 0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.attach_money_rounded,
                                      color: tarifColor, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tarif qui sera appliqué',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: tarifColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${tarif.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: tarifColor,
                                ),
                              ),
                              Text(
                                tarifSource,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: tarifColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ConsumptionUnit>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unité de mesure *',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUnits
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _getUnitTypeColor(unit.type)
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        unit.symbol,
                                        style: TextStyle(
                                          color: _getUnitTypeColor(unit.type),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            unit.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            _getTypeName(unit.type),
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedUnit = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('${localizations.readingMonth} *'),
                      subtitle: Text(
                          DateFormat('MMMM yyyy', localizations.localeName)
                              .format(selectedMoisReleve)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedMoisReleve,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedMoisReleve =
                              DateTime(date.year, date.month, 1));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(localizations.creationDate),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setDialogState(() => selectedDate = date);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: commentaireController,
                      decoration: InputDecoration(
                        labelText:
                            '${localizations.comment} (${localizations.optional})',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => _saveReleve(
                releve,
                selectedLocataireId,
                ancienIndexController.text,
                nouvelIndexController.text,
                selectedDate,
                selectedMoisReleve,
                commentaireController.text,
                selectedUnit,
              ),
              child: Text(
                  releve == null ? localizations.add : localizations.modify),
            ),
          ],
        ),
      ),
    );
  }

  void _showReleveDetails(Releve releve) {
    // TODO: Implémenter l'affichage des détails
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Détails du relevé - En cours de développement',
    );
  }

  Future<void> _navigateToPaymentManagement(Releve releve) async {
    final locataire = _getLocataire(releve.locataireId);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentManagementScreen(
          releve: releve,
          locataire: locataire,
        ),
      ),
    );

    // Recharger les données si un paiement a été effectué
    if (result == true) {
      await _loadData();
    }
  }

  void _togglePaymentStatus(Releve releve) {
    // TODO: Implémenter le changement de statut
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Changement de statut - En cours de développement',
    );
  }

  void _confirmDelete(Releve releve) {
    // TODO: Implémenter la confirmation de suppression
    EnhancedSnackBar.showInfo(
      context: context,
      message: 'Suppression - En cours de développement',
    );
  }
}
