import 'package:flutter/material.dart';
import 'package:rentilax_tracker/l10n/l10n_extensions.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../widgets/enhanced_search_bar.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/enhanced_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_snackbar.dart';

class CitesScreen extends StatefulWidget {
  const CitesScreen({super.key});

  @override
  State<CitesScreen> createState() => _CitesScreenState();
}

class _CitesScreenState extends State<CitesScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Cite> _allCites = [];
  List<Cite> _filteredCites = [];
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
    _loadCites();
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

  Future<void> _loadCites() async {
    setState(() => _isLoading = true);
    try {
      final cites = await _databaseService.getCites();
      setState(() {
        _allCites = cites;
        _filteredCites = cites;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredCites = _allCites.where((cite) {
        // Filtre de recherche
        if (_searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          final matchesName = cite.nom.toLowerCase().contains(query);
          final matchesAddress =
              cite.adresse?.toLowerCase().contains(query) ?? false;
          if (!matchesName && !matchesAddress) return false;
        }

        // Filtres de date
        if (_activeFilters['date_start'] != null) {
          final startDate = _activeFilters['date_start'] as DateTime;
          if (cite.dateCreation.isBefore(startDate)) return false;
        }

        if (_activeFilters['date_end'] != null) {
          final endDate = _activeFilters['date_end'] as DateTime;
          if (cite.dateCreation.isAfter(endDate)) return false;
        }

        return true;
      }).toList();

      // Tri
      if (_activeFilters['sort'] == 'name_asc') {
        _filteredCites.sort((a, b) => a.nom.compareTo(b.nom));
      } else if (_activeFilters['sort'] == 'name_desc') {
        _filteredCites.sort((a, b) => b.nom.compareTo(a.nom));
      } else if (_activeFilters['sort'] == 'date_asc') {
        _filteredCites.sort((a, b) => a.dateCreation.compareTo(b.dateCreation));
      } else if (_activeFilters['sort'] == 'date_desc') {
        _filteredCites.sort((a, b) => b.dateCreation.compareTo(a.dateCreation));
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
          FilterValue(key: 'date_asc', label: 'Date (Plus ancien)'),
          FilterValue(key: 'date_desc', label: 'Date (Plus récent)'),
        ],
      ),
      const FilterOption(
        key: 'date',
        label: 'Période de création',
        type: FilterType.dateRange,
      ),
    ];

    showFilterBottomSheet(
      context: context,
      title: 'Filtrer les cités',
      options: filterOptions,
      currentFilters: _activeFilters,
      onApplyFilters: (filters) {
        setState(() {
          _activeFilters = filters;
        });
        _applyFilters();
      },
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_activeFilters['sort'] != null) count++;
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
        title: localizations.citesScreenTitle,
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
            hintText: 'Rechercher une cité...',
            onChanged: _onSearchChanged,
            showFilters: true,
            onFilterTap: _showFilters,
            filterCount: _activeFilterCount,
          ),

          // Statistiques rapides
          if (!_isLoading && _allCites.isNotEmpty)
            Container(
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
                    '${_allCites.length}',
                    Icons.location_city_rounded,
                  ),
                  _buildStatItem(
                    context,
                    'Affichées',
                    '${_filteredCites.length}',
                    Icons.visibility_rounded,
                  ),
                  _buildStatItem(
                    context,
                    'Avec adresse',
                    '${_allCites.where((c) => c.adresse != null && c.adresse!.isNotEmpty).length}',
                    Icons.location_on_rounded,
                  ),
                ],
              ),
            ),

          // Liste des cités
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredCites.isEmpty
                    ? _buildEmptyState(localizations)
                    : RefreshIndicator(
                        onRefresh: _loadCites,
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 80),
                          itemCount: _filteredCites.length,
                          itemBuilder: (context, index) {
                            final cite = _filteredCites[index];
                            return AnimatedListItem(
                              index: index,
                              child: _buildCiteCard(cite, localizations),
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
                _showCiteDialog();
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle cité'),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
          );
        },
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
                  : Icons.location_city_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Aucune cité trouvée'
                : localizations.noCitiesRecorded,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _activeFilters.isNotEmpty
                ? 'Essayez de modifier vos critères de recherche'
                : 'Commencez par ajouter votre première cité',
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
          ],
        ],
      ),
    );
  }

  Widget _buildCiteCard(Cite cite, dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.location_city_rounded,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      title: Text(cite.nom),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (cite.adresse != null && cite.adresse!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    cite.adresse!,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                'Créée le ${cite.dateCreation.day}/${cite.dateCreation.month}/${cite.dateCreation.year}',
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
          if (value == 'edit') {
            _showCiteDialog(cite);
          } else if (value == 'delete') {
            _confirmDelete(cite);
          }
        },
      ),
      onTap: () {
        // Optionnel: navigation vers les détails de la cité
      },
    );
  }

  void _showCiteDialog([Cite? cite]) {
    final localizations = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final nomController = TextEditingController(text: cite?.nom ?? '');
    final adresseController = TextEditingController(text: cite?.adresse ?? '');
    final formKey = GlobalKey<FormState>();

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
          child: Form(
            key: formKey,
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
                        color:
                            colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        cite == null
                            ? Icons.add_location_rounded
                            : Icons.edit_location_rounded,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cite == null
                                ? localizations.addCity
                                : localizations.editCity,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            cite == null
                                ? 'Ajouter une nouvelle cité'
                                : 'Modifier les informations',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Formulaire
                TextFormField(
                  controller: nomController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: '${localizations.cityName} *',
                    hintText: 'Ex: Résidence Les Palmiers',
                    prefixIcon: const Icon(Icons.location_city_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom de la cité est requis';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: adresseController,
                  decoration: InputDecoration(
                    labelText:
                        '${localizations.address} (${localizations.optional})',
                    hintText: 'Ex: Avenue de la République, Dakar',
                    prefixIcon: const Icon(Icons.location_on_rounded),
                  ),
                  maxLines: 2,
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
                      onPressed: () {
                        if (formKey.currentState!.validate()) {
                          _saveCite(
                              cite, nomController.text, adresseController.text);
                        }
                      },
                      icon: Icon(cite == null
                          ? Icons.add_rounded
                          : Icons.save_rounded),
                      label: Text(cite == null
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

  Future<void> _saveCite(Cite? existingCite, String nom, String adresse) async {
    final localizations = context.l10n;

    try {
      if (existingCite == null) {
        // Ajouter nouvelle cité
        final nouvelleCite = Cite(
          nom: nom.trim(),
          adresse: adresse.trim().isEmpty ? null : adresse.trim(),
          dateCreation: DateTime.now(),
        );
        await _databaseService.insertCite(nouvelleCite);
      } else {
        // Modifier cité existante
        final citeModifiee = Cite(
          id: existingCite.id,
          nom: nom.trim(),
          adresse: adresse.trim().isEmpty ? null : adresse.trim(),
          dateCreation: existingCite.dateCreation,
        );
        await _databaseService.updateCite(citeModifiee);
      }

      if (!mounted) return;
      Navigator.pop(context);
      await _loadCites();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: existingCite == null
            ? localizations.cityAddedSuccessfully
            : localizations.cityModifiedSuccessfully,
      );
    } catch (e) {
      if (!mounted) return;
      EnhancedSnackBar.showError(
        context: context,
        message: '${localizations.errorSavingCity}: $e',
      );
    }
  }

  void _confirmDelete(Cite cite) {
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
                localizations.confirmDeleteCity(cite.nom),
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
                      onPressed: () => _deleteCite(cite),
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

  Future<void> _deleteCite(Cite cite) async {
    final localizations = context.l10n;
    try {
      await _databaseService.deleteCite(cite.id!);
      if (!mounted) return;
      Navigator.pop(context);
      await _loadCites();

      EnhancedSnackBar.showSuccess(
        context: context,
        message: localizations.cityDeletedSuccessfully,
        actionLabel: 'Annuler',
        onActionPressed: () {
          // TODO: Implémenter l'annulation (undo)
        },
      );
    } catch (e) {
      if (!mounted) return;
      EnhancedSnackBar.showError(
        context: context,
        message: '${localizations.errorDeletingCity}: $e',
      );
    }
  }
}
