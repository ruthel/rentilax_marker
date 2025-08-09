import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/enhanced_search_bar.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/enhanced_card.dart';

class EnhancedGlobalSearchScreen extends StatefulWidget {
  const EnhancedGlobalSearchScreen({super.key});

  @override
  State<EnhancedGlobalSearchScreen> createState() =>
      _EnhancedGlobalSearchScreenState();
}

class _EnhancedGlobalSearchScreenState extends State<EnhancedGlobalSearchScreen>
    with TickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<SearchResult> _searchResults = [];
  bool _isLoading = false;
  String _currentQuery = '';
  SearchCategory _selectedCategory = SearchCategory.all;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedCategory = SearchCategory.values[_tabController.index];
      });
      if (_currentQuery.isNotEmpty) {
        _performSearch(_currentQuery);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _currentQuery = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _currentQuery = query;
    });

    try {
      final results = <SearchResult>[];
      final searchQuery = query.toLowerCase().trim();

      // Recherche dans les cités
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.cities) {
        final cites = await _databaseService.getCites();
        for (final cite in cites) {
          if (cite.nom.toLowerCase().contains(searchQuery) ||
              (cite.adresse?.toLowerCase().contains(searchQuery) ?? false)) {
            results.add(SearchResult(
              type: SearchResultType.city,
              title: cite.nom,
              subtitle: cite.adresse ?? 'Aucune adresse',
              data: cite,
              icon: Icons.location_city_rounded,
              color: Colors.blue,
            ));
          }
        }
      }

      // Recherche dans les locataires
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.tenants) {
        final locataires = await _databaseService.getLocataires();
        for (final locataire in locataires) {
          if (locataire.nom.toLowerCase().contains(searchQuery) ||
              locataire.prenom.toLowerCase().contains(searchQuery) ||
              (locataire.contact?.toLowerCase().contains(searchQuery) ??
                  false) ||
              locataire.numeroLogement.toLowerCase().contains(searchQuery)) {
            // Récupérer le nom de la cité
            String citeName = 'Cité inconnue';
            try {
              final cite = await _databaseService.getCiteById(locataire.citeId);
              citeName = cite?.nom ?? 'Cité inconnue';
            } catch (e) {
              // Ignore l'erreur
            }

            results.add(SearchResult(
              type: SearchResultType.tenant,
              title: '${locataire.prenom} ${locataire.nom}',
              subtitle: 'Logement ${locataire.numeroLogement} - $citeName',
              data: locataire,
              icon: Icons.person_rounded,
              color: Colors.green,
            ));
          }
        }
      }

      // Recherche dans les relevés
      if (_selectedCategory == SearchCategory.all ||
          _selectedCategory == SearchCategory.readings) {
        final releves = await _databaseService.getReleves();
        for (final releve in releves) {
          // Récupérer les informations du locataire
          final locataire =
              await _databaseService.getLocataireById(releve.locataireId);
          if (locataire != null) {
            final locataireFullName = '${locataire.prenom} ${locataire.nom}';
            final montantStr = releve.montant.toString();
            final consommationStr = releve.consommation.toString();

            if (locataireFullName.toLowerCase().contains(searchQuery) ||
                montantStr.contains(searchQuery) ||
                consommationStr.contains(searchQuery) ||
                locataire.numeroLogement.toLowerCase().contains(searchQuery)) {
              results.add(SearchResult(
                type: SearchResultType.reading,
                title: 'Relevé de $locataireFullName',
                subtitle:
                    'Logement ${locataire.numeroLogement} - ${releve.montant.toStringAsFixed(0)} FCFA',
                data: releve,
                icon: Icons.assessment_rounded,
                color: Colors.orange,
                additionalInfo: 'Consommation: ${releve.consommation}',
              ));
            }
          }
        }
      }

      // Trier les résultats par pertinence
      results.sort((a, b) {
        // Priorité aux correspondances exactes dans le titre
        final aExactMatch = a.title.toLowerCase() == searchQuery;
        final bExactMatch = b.title.toLowerCase() == searchQuery;

        if (aExactMatch && !bExactMatch) return -1;
        if (!aExactMatch && bExactMatch) return 1;

        // Puis par correspondances au début du titre
        final aStartsWithMatch = a.title.toLowerCase().startsWith(searchQuery);
        final bStartsWithMatch = b.title.toLowerCase().startsWith(searchQuery);

        if (aStartsWithMatch && !bStartsWithMatch) return -1;
        if (!aStartsWithMatch && bStartsWithMatch) return 1;

        // Enfin par ordre alphabétique
        return a.title.compareTo(b.title);
      });

      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la recherche: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ModernAppBar(
        title: 'Recherche globale',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Tout', icon: Icon(Icons.search_rounded, size: 18)),
            Tab(
                text: 'Cités',
                icon: Icon(Icons.location_city_rounded, size: 18)),
            Tab(text: 'Locataires', icon: Icon(Icons.people_rounded, size: 18)),
            Tab(
                text: 'Relevés',
                icon: Icon(Icons.assessment_rounded, size: 18)),
          ],
          labelStyle: theme.textTheme.labelMedium,
          unselectedLabelStyle: theme.textTheme.labelMedium,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
        ),
      ),
      body: Column(
        children: [
          // Barre de recherche
          EnhancedSearchBar(
            hintText: _getSearchHint(),
            onChanged: _performSearch,
            onClear: () {
              setState(() {
                _searchResults = [];
                _currentQuery = '';
              });
            },
          ),

          // Statistiques de recherche
          if (_currentQuery.isNotEmpty && !_isLoading)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_searchResults.length} résultat(s) trouvé(s) pour "$_currentQuery"',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

          // Résultats de recherche
          Expanded(
            child: _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  String _getSearchHint() {
    switch (_selectedCategory) {
      case SearchCategory.cities:
        return 'Rechercher une cité...';
      case SearchCategory.tenants:
        return 'Rechercher un locataire...';
      case SearchCategory.readings:
        return 'Rechercher un relevé...';
      case SearchCategory.all:
        return 'Rechercher partout...';
    }
  }

  Widget _buildSearchResults() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Recherche en cours...'),
          ],
        ),
      );
    }

    if (_currentQuery.isEmpty) {
      return _buildEmptyState();
    }

    if (_searchResults.isEmpty) {
      return _buildNoResultsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return AnimatedListItem(
          index: index,
          child: _buildSearchResultCard(result),
        );
      },
    );
  }

  Widget _buildEmptyState() {
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
              Icons.search_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Recherche globale',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tapez pour rechercher dans les cités,\nlocataires et relevés',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
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
              Icons.search_off_rounded,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucun résultat trouvé',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez avec d\'autres mots-clés\nou changez de catégorie',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(SearchResult result) {
    final theme = Theme.of(context);

    return EnhancedListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: result.color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          result.icon,
          color: result.color,
          size: 20,
        ),
      ),
      title: Text(result.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(result.subtitle),
          if (result.additionalInfo != null) ...[
            const SizedBox(height: 4),
            Text(
              result.additionalInfo!,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () => _handleResultTap(result),
    );
  }

  void _handleResultTap(SearchResult result) {
    // TODO: Implémenter la navigation vers les détails selon le type
    switch (result.type) {
      case SearchResultType.city:
        // Naviguer vers les détails de la cité
        break;
      case SearchResultType.tenant:
        // Naviguer vers les détails du locataire
        break;
      case SearchResultType.reading:
        // Naviguer vers les détails du relevé
        break;
    }
  }
}

class SearchResult {
  final SearchResultType type;
  final String title;
  final String subtitle;
  final dynamic data;
  final IconData icon;
  final Color color;
  final String? additionalInfo;

  const SearchResult({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.data,
    required this.icon,
    required this.color,
    this.additionalInfo,
  });
}

enum SearchResultType {
  city,
  tenant,
  reading,
}

enum SearchCategory {
  all,
  cities,
  tenants,
  readings,
}
