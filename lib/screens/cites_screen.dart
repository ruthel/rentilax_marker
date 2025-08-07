import 'package:flutter/material.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import '../models/cite.dart';
import '../services/database_service.dart';

class CitesScreen extends StatefulWidget {
  const CitesScreen({super.key});

  @override
  State<CitesScreen> createState() => _CitesScreenState();
}

class _CitesScreenState extends State<CitesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Cite> _cites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCites();
  }

  Future<void> _loadCites() async {
    setState(() => _isLoading = true);
    try {
      final cites = await _databaseService.getCites();
      setState(() {
        _cites = cites;
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
    final localizations = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.citesScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cites.isEmpty
              ? Center(
                  child: Text(
                    localizations.noCitiesRecorded,
                    style: const TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCites,
                  child: ListView.builder(
                    itemCount: _cites.length,
                    itemBuilder: (context, index) {
                      final cite = _cites[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.location_city),
                          ),
                          title: Text(
                            cite.nom,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle:
                              cite.adresse != null ? Text(cite.adresse!) : null,
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    const Icon(Icons.edit),
                                    const SizedBox(width: 8),
                                    Text(localizations.modify),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    const Icon(Icons.delete, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Text(localizations.delete,
                                        style:
                                            const TextStyle(color: Colors.red)),
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
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCiteDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCiteDialog([Cite? cite]) {
    final localizations = context.l10n;
    final nomController = TextEditingController(text: cite?.nom ?? '');
    final adresseController = TextEditingController(text: cite?.adresse ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text(cite == null ? localizations.addCity : localizations.editCity),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: InputDecoration(
                labelText: '${localizations.cityName} *',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adresseController,
              decoration: InputDecoration(
                labelText:
                    '${localizations.address} (${localizations.optional})',
                border: const OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () =>
                _saveCite(cite, nomController.text, adresseController.text),
            child: Text(cite == null ? localizations.add : localizations.save),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCite(Cite? existingCite, String nom, String adresse) async {
    final localizations = context.l10n;
    if (nom.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.cityRequired)),
      );
      return;
    }

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
      _loadCites();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingCite == null
              ? localizations.cityAddedSuccessfully
              : localizations.cityModifiedSuccessfully),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorSavingCity}: $e')),
      );
    }
  }

  void _confirmDelete(Cite cite) {
    final localizations = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDeletion),
        content: Text(localizations.confirmDeleteCity(cite.nom)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => _deleteCite(cite),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCite(Cite cite) async {
    final localizations = context.l10n;
    try {
      await _databaseService.deleteCite(cite.id!);
      if (!mounted) return;
      Navigator.pop(context);
      _loadCites();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.cityDeletedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorDeletingCity}: $e')),
      );
    }
  }
}
