import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_search_bar.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/enhanced_snackbar.dart';
import 'locataire_history_screen.dart';

class EnhancedLocatairesScreen extends StatefulWidget {
  const EnhancedLocatairesScreen({super.key});

  @override
  State<EnhancedLocatairesScreen> createState() =>
      _EnhancedLocatairesScreenState();
}

class _EnhancedLocatairesScreenState extends State<EnhancedLocatairesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Locataire> _allLocataires = [];
  List<Locataire> _filteredLocataires = [];
  List<Cite> _cites = [];
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
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      setState(() {
        _allLocataires = locataires;
        _filteredLocataires = locataires;
        _cites = cites;
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
      _filteredLocataires = _allLocataires.where((locataire) {
        // Filtre de recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesName = '${locataire.prenom} ${locataire.nom}'
              .toLowerCase()
              .contains(query);
          final matchesLogement =
              locataire.numeroLogement.toLowerCase().contains(query);
          final matchesContact =
              locataire.contact?.toLowerCase().contains(query) ?? false;
          if (!matchesName && !matchesLogement && !matchesContact) return false;
        }

        // Filtre par cité
        if (_activeFilters['cite_id'] != null) {
          if (locataire.citeId != _activeFilters['cite_id']) return false;
        }

        // Filtre par statut de tarif
        if (_activeFilters['tarif_status'] != null) {
          final hasCustomTarif = locataire.tarifPersonnalise != null;
          if (_activeFilters['tarif_status'] == 'custom' && !hasCustomTarif) {
            return false;
          }
          if (_activeFilters['tarif_status'] == 'default' && hasCustomTarif) {
            return false;
          }
        }

        // Filtre par date d'entrée
        if (_activeFilters['date_start'] != null) {
          final startDate = _activeFilters['date_start'] as DateTime;
          if (locataire.dateEntree.isBefore(startDate)) return false;
        }

        if (_activeFilters['date_end'] != null) {
          final endDate = _activeFilters['date_end'] as DateTime;
          if (locataire.dateEntree.isAfter(endDate)) return false;
        }

        return true;
      }).toList();

      // Tri
      if (_activeFilters['sort'] == 'name_asc') {
        _filteredLocataires.sort(
            (a, b) => '${a.prenom} ${a.nom}'.compareTo('${b.prenom} ${b.nom}'));
      } else if (_activeFilters['sort'] == 'name_desc') {
        _filteredLocataires.sort(
            (a, b) => '${b.prenom} ${b.nom}'.compareTo('${a.prenom} ${a.nom}'));
      } else if (_activeFilters['sort'] == 'logement_asc') {
        _filteredLocataires
            .sort((a, b) => a.numeroLogement.compareTo(b.numeroLogement));
      } else if (_activeFilters['sort'] == 'logement_desc') {
        _filteredLocataires
            .sort((a, b) => b.numeroLogement.compareTo(a.numeroLogement));
      } else if (_activeFilters['sort'] == 'date_asc') {
        _filteredLocataires
            .sort((a, b) => a.dateEntree.compareTo(b.dateEntree));
      } else if (_activeFilters['sort'] == 'date_desc') {
        _filteredLocataires
            .sort((a, b) => b.dateEntree.compareTo(a.dateEntree));
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
          FilterValue(key: 'name_asc', label: 'Nom (A-Z)'),
          FilterValue(key: 'name_desc', label: 'Nom (Z-A)'),
          FilterValue(key: 'logement_asc', label: 'Logement (A-Z)'),
          FilterValue(key: 'logement_desc', label: 'Logement (Z-A)'),
          FilterValue(key: 'date_asc', label: 'Date entrée (Plus ancien)'),
          FilterValue(key: 'date_desc', label: 'Date entrée (Plus récent)'),
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
        key: 'tarif_status',
        label: 'Type de tarif',
        type: FilterType.radio,
        values: [
          FilterValue(key: '', label: 'Tous'),
          FilterValue(key: 'custom', label: 'Tarif personnalisé'),
          FilterValue(key: 'default', label: 'Tarif par défaut'),
        ],
      ),
      const FilterOption(
        key: 'date',
        label: 'Période d\'entrée',
        type: FilterType.dateRange,
      ),
    ];

    showFilterBottomSheet(
      context: context,
      title: 'Filtrer les locataires',
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
    if (_activeFilters['cite_id'] != null) count++;
    if (_activeFilters['tarif_status'] != null) count++;
    if (_activeFilters['date_start'] != null ||
        _activeFilters['date_end'] != null) {
      count++;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.locatairesScreenTitle,
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
            hintText: 'Rechercher un locataire...',
            onChanged: _onSearchChanged,
            showFilters: true,
            onFilterTap: _showFilters,
            filterCount: _activeFilterCount,
          ),

          // Statistiques rapides
          if (!_isLoading && _allLocataires.isNotEmpty) _buildStatsSection(),

          // Liste des locataires
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLocataires.isEmpty
                    ? _buildEmptyState(localizations)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filteredLocataires.length,
                          itemBuilder: (context, index) {
                            final locataire = _filteredLocataires[index];
                            return AnimatedListItem(
                              index: index,
                              child: _buildModernTenantCard(
                                  locataire, localizations),
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
                _showLocataireDialog();
              },
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Nouveau locataire'),
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

    final totalLocataires = _allLocataires.length;
    final locatairesWithCustomTarif =
        _allLocataires.where((l) => l.tarifPersonnalise != null).length;
    final citesWithLocataires =
        _allLocataires.map((l) => l.citeId).toSet().length;

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
            '$totalLocataires',
            Icons.people_rounded,
          ),
          _buildStatItem(
            context,
            'Affichés',
            '${_filteredLocataires.length}',
            Icons.visibility_rounded,
          ),
          _buildStatItem(
            context,
            'Tarif custom',
            '$locatairesWithCustomTarif',
            Icons.attach_money_rounded,
          ),
          _buildStatItem(
            context,
            'Cités',
            '$citesWithLocataires',
            Icons.location_city_rounded,
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
                  : Icons.people_outline_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Aucun locataire trouvé'
                : localizations.noTenantsRecorded,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Essayez de modifier vos critères de recherche'
                : 'Commencez par ajouter votre premier locataire',
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
              onPressed: () => _showLocataireDialog(),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(localizations.addTenant),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildModernTenantCard(Locataire locataire, dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final citeNom = _getCiteNom(locataire.citeId);

    return EnhancedListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.person_rounded,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(locataire.nomComplet),
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
              Expanded(
                child: Text(
                  citeNom,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.home_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Logement ${locataire.numeroLogement}',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
              if (locataire.tarifPersonnalise != null) ...[
                const SizedBox(width: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Tarif perso',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Depuis le ${DateFormat('dd/MM/yyyy').format(locataire.dateEntree)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
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
          PopupMenuItem(
            value: 'history',
            child: Row(
              children: [
                Icon(Icons.history_rounded,
                    size: 18, color: colorScheme.primary),
                const SizedBox(width: 12),
                const Text('Historique'),
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
          if (value == 'history') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    LocataireHistoryScreen(locataire: locataire),
              ),
            );
          } else if (value == 'edit') {
            _showLocataireDialog(locataire);
          } else if (value == 'delete') {
            _confirmDelete(locataire);
          }
        },
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LocataireHistoryScreen(locataire: locataire),
          ),
        );
      },
    );
  }

  String _getCiteNom(int citeId) {
    final cite = _cites.firstWhere(
      (c) => c.id == citeId,
      orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
    );
    return cite.nom;
  }

  void _showLocataireDialog([Locataire? locataire]) {
    final localizations = context.l10n;
    if (_cites.isEmpty) {
      EnhancedSnackBar.showWarning(
        context: context,
        message:
            'Vous devez d\'abord créer une cité avant d\'ajouter un locataire',
      );
      return;
    }

    final nomController = TextEditingController(text: locataire?.nom ?? '');
    final prenomController =
        TextEditingController(text: locataire?.prenom ?? '');
    final numeroLogementController =
        TextEditingController(text: locataire?.numeroLogement ?? '');
    final telephoneController =
        TextEditingController(text: locataire?.contact ?? '');
    final emailController = TextEditingController(text: locataire?.email ?? '');
    final tarifController = TextEditingController(
        text: locataire?.tarifPersonnalise?.toString() ?? '');

    int selectedCiteId = locataire?.citeId ?? _cites.first.id!;
    DateTime selectedDate = locataire?.dateEntree ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        locataire == null
                            ? Icons.person_add_rounded
                            : Icons.edit_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            locataire == null
                                ? localizations.addTenant
                                : localizations.editTenant,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          Text(
                            locataire == null
                                ? 'Ajouter un nouveau locataire'
                                : 'Modifier les informations',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Formulaire
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: prenomController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: '${localizations.firstName} *',
                            hintText: 'Ex: Jean',
                            prefixIcon:
                                const Icon(Icons.person_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: nomController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: '${localizations.lastName} *',
                            hintText: 'Ex: Dupont',
                            prefixIcon: const Icon(Icons.person_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<int>(
                          value: selectedCiteId,
                          decoration: InputDecoration(
                            labelText: 'Cité *',
                            prefixIcon: const Icon(Icons.location_city_rounded),
                          ),
                          items: _cites
                              .map((cite) => DropdownMenuItem(
                                    value: cite.id,
                                    child: Text(cite.nom),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selectedCiteId = value);
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: numeroLogementController,
                          decoration: InputDecoration(
                            labelText: '${localizations.housingNumber} *',
                            hintText: 'Ex: A12, B05',
                            prefixIcon: const Icon(Icons.home_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: telephoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: localizations.phone,
                            hintText: 'Ex: +221 77 123 45 67',
                            prefixIcon: const Icon(Icons.phone_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: localizations.email,
                            hintText: 'Ex: jean.dupont@email.com',
                            prefixIcon: const Icon(Icons.email_rounded),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: tarifController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: localizations.customRate,
                            hintText:
                                'Laisser vide pour utiliser le tarif de base',
                            prefixIcon: const Icon(Icons.attach_money_rounded),
                            suffixText: 'FCFA',
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(Icons.calendar_today_rounded),
                          title: Text(localizations.entryDate),
                          subtitle: Text(
                              DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: () => _saveLocataire(
                        locataire,
                        prenomController.text,
                        nomController.text,
                        selectedCiteId,
                        numeroLogementController.text,
                        telephoneController.text,
                        emailController.text,
                        tarifController.text,
                        selectedDate,
                      ),
                      icon: Icon(locataire == null
                          ? Icons.add_rounded
                          : Icons.save_rounded),
                      label: Text(locataire == null
                          ? localizations.add
                          : localizations.save),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveLocataire(
    Locataire? existingLocataire,
    String prenom,
    String nom,
    int citeId,
    String numeroLogement,
    String telephone,
    String email,
    String tarif,
    DateTime dateEntree,
  ) async {
    final localizations = context.l10n;

    if (prenom.trim().isEmpty ||
        nom.trim().isEmpty ||
        numeroLogement.trim().isEmpty) {
      EnhancedSnackBar.showError(
        context: context,
        message: localizations.firstNameLastNameHousingRequired,
      );
      return;
    }

    double? tarifPersonnalise;
    if (tarif.trim().isNotEmpty) {
      tarifPersonnalise = double.tryParse(tarif.trim());
      if (tarifPersonnalise == null) {
        EnhancedSnackBar.showError(
          context: context,
          message: localizations.invalidRate,
        );
        return;
      }
    }

    // Vérifier l'unicité du numéro de logement dans la cité
    final existingLocataireWithSameNumber = _allLocataires.firstWhere(
      (l) =>
          l.citeId == citeId &&
          l.numeroLogement.toLowerCase() ==
              numeroLogement.trim().toLowerCase() &&
          l.id != existingLocataire?.id,
      orElse: () => Locataire(
          nom: '',
          prenom: '',
          citeId: 0,
          numeroLogement: '',
          dateEntree: DateTime.now()),
    );

    if (existingLocataireWithSameNumber.id != null) {
      if (!mounted) return;
      EnhancedSnackBar.showError(
        context: context,
        message: localizations.housingNumberExists(numeroLogement.trim()),
      );
      return;
    }

    try {
      if (existingLocataire == null) {
        // Ajouter nouveau locataire
        final nouveauLocataire = Locataire(
          prenom: prenom.trim(),
          nom: nom.trim(),
          citeId: citeId,
          numeroLogement: numeroLogement.trim(),
          contact: telephone.trim().isEmpty ? null : telephone.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
          tarifPersonnalise: tarifPersonnalise,
          dateEntree: dateEntree,
        );
        await _databaseService.insertLocataire(nouveauLocataire);
      } else {
        // Modifier locataire existant
        final locataireModifie = Locataire(
          id: existingLocataire.id,
          prenom: prenom.trim(),
          nom: nom.trim(),
          citeId: citeId,
          numeroLogement: numeroLogement.trim(),
          contact: telephone.trim().isEmpty ? null : telephone.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
          tarifPersonnalise: tarifPersonnalise,
          dateEntree: dateEntree,
        );
        await _databaseService.updateLocataire(locataireModifie);
      }

      if (!mounted) return;
      Navigator.pop(context);
      await _loadData();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: existingLocataire == null
            ? localizations.tenantAddedSuccessfully
            : localizations.tenantModifiedSuccessfully,
      );
    } catch (e) {
      if (!mounted) return;
      EnhancedSnackBar.showError(
        context: context,
        message: '${localizations.errorSavingTenant}: $e',
      );
    }
  }

  void _confirmDelete(Locataire locataire) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône d'avertissement
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: Colors.red,
                  size: 32,
                ),
              ),

              const SizedBox(height: 16),

              Text(
                localizations.confirmDeletion,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Êtes-vous sûr de vouloir supprimer ${locataire.nomComplet} ?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(localizations.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _deleteLocataire(locataire),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.delete_rounded),
                      label: Text(localizations.delete),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLocataire(Locataire locataire) async {
    final localizations = context.l10n;
    try {
      await _databaseService.deleteLocataire(locataire.id!);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadData();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: localizations.tenantDeletedSuccessfully,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      EnhancedSnackBar.showError(
        context: context,
        message: '${localizations.errorDeletingTenant}: $e',
      );
    }
  }
}
