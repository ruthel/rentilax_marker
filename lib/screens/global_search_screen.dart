import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/locataire.dart';
import '../models/releve.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../l10n/generated/app_localizations.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Locataire> _locataires = [];
  List<Releve> _releves = [];
  List<Cite> _cites = [];

  List<Locataire> _filteredLocataires = [];
  List<Releve> _filteredReleves = [];
  List<Cite> _filteredCites = [];

  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final locataires = await _databaseService.getLocataires();
      final releves = await _databaseService.getReleves();
      final cites = await _databaseService.getCites();

      setState(() {
        _locataires = locataires;
        _releves = releves;
        _cites = cites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _performSearch();
    });
  }

  void _performSearch() {
    if (_searchQuery.isEmpty) {
      _filteredLocataires = [];
      _filteredReleves = [];
      _filteredCites = [];
      return;
    }

    // Recherche dans les locataires
    _filteredLocataires = _locataires.where((locataire) {
      return locataire.nomComplet.toLowerCase().contains(_searchQuery) ||
          locataire.numeroLogement.toLowerCase().contains(_searchQuery) ||
          locataire.telephone?.toLowerCase().contains(_searchQuery) == true ||
          locataire.email?.toLowerCase().contains(_searchQuery) == true;
    }).toList();

    // Recherche dans les cités
    _filteredCites = _cites.where((cite) {
      return cite.nom.toLowerCase().contains(_searchQuery) ||
          cite.adresse?.toLowerCase().contains(_searchQuery) == true;
    }).toList();

    // Recherche dans les relevés (par commentaire)
    _filteredReleves = _releves.where((releve) {
      return releve.commentaire?.toLowerCase().contains(_searchQuery) == true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Recherche Globale'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher...',
                hintText: 'Nom, numéro, email, cité, commentaire...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _searchQuery.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Commencez à taper pour rechercher',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Locataires • Cités • Relevés',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildSearchResults(localizations),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(AppLocalizations localizations) {
    final totalResults = _filteredLocataires.length +
        _filteredCites.length +
        _filteredReleves.length;

    if (totalResults == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun résultat trouvé',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Essayez avec d\'autres mots-clés',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Résumé des résultats
        Card(
          color: Colors.blue.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  '$totalResults résultat(s) trouvé(s)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Résultats Locataires
        if (_filteredLocataires.isNotEmpty) ...[
          _buildSectionHeader(
              'Locataires', _filteredLocataires.length, Icons.people),
          ..._filteredLocataires
              .map((locataire) => _buildLocataireCard(locataire)),
          const SizedBox(height: 16),
        ],

        // Résultats Cités
        if (_filteredCites.isNotEmpty) ...[
          _buildSectionHeader(
              'Cités', _filteredCites.length, Icons.location_city),
          ..._filteredCites.map((cite) => _buildCiteCard(cite)),
          const SizedBox(height: 16),
        ],

        // Résultats Relevés
        if (_filteredReleves.isNotEmpty) ...[
          _buildSectionHeader(
              'Relevés', _filteredReleves.length, Icons.assessment),
          ..._filteredReleves.map((releve) => _buildReleveCard(releve)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocataireCard(Locataire locataire) {
    final cite = _cites.firstWhere(
      (c) => c.id == locataire.citeId,
      orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.person, color: Colors.white),
        ),
        title: Text(
          locataire.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${cite.nom} - Logement ${locataire.numeroLogement}'),
            if (locataire.telephone != null) Text('📞 ${locataire.telephone}'),
            if (locataire.email != null) Text('📧 ${locataire.email}'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers les détails du locataire
          Navigator.pop(context);
          // Ici vous pouvez naviguer vers l'écran de détails du locataire
        },
      ),
    );
  }

  Widget _buildCiteCard(Cite cite) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.blue,
          child: Icon(Icons.location_city, color: Colors.white),
        ),
        title: Text(
          cite.nom,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: cite.adresse != null ? Text(cite.adresse!) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers les détails de la cité
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildReleveCard(Releve releve) {
    final locataire = _locataires.firstWhere(
      (l) => l.id == releve.locataireId,
      orElse: () => Locataire(
        nom: 'Inconnu',
        prenom: '',
        citeId: 0,
        numeroLogement: '',
        dateEntree: DateTime.now(),
      ),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: releve.isPaid ? Colors.green : Colors.orange,
          child: const Icon(Icons.assessment, color: Colors.white),
        ),
        title: Text(
          locataire.nomComplet,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                '${DateFormat('MMMM yyyy', 'fr_FR').format(releve.moisReleve)}'),
            if (releve.commentaire != null)
              Text(
                '💬 ${releve.commentaire}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            Text('${releve.montant.toStringAsFixed(0)} FCFA'),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Navigation vers les détails du relevé
          Navigator.pop(context);
        },
      ),
    );
  }
}
