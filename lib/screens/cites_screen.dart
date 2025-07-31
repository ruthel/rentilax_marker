import 'package:flutter/material.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Cités'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cites.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune cité enregistrée',
                    style: TextStyle(fontSize: 18),
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
                            subtitle: cite.adresse != null
                                ? Text(cite.adresse!)
                                : null,
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit),
                                      SizedBox(width: 8),
                                      Text('Modifier'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Supprimer', style: TextStyle(color: Colors.red)),
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
    final nomController = TextEditingController(text: cite?.nom ?? '');
    final adresseController = TextEditingController(text: cite?.adresse ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(cite == null ? 'Ajouter une cité' : 'Modifier la cité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomController,
              decoration: const InputDecoration(
                labelText: 'Nom de la cité *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: adresseController,
              decoration: const InputDecoration(
                labelText: 'Adresse (optionnel)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _saveCite(cite, nomController.text, adresseController.text),
            child: Text(cite == null ? 'Ajouter' : 'Modifier'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCite(Cite? existingCite, String nom, String adresse) async {
    if (nom.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de la cité est obligatoire')),
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

      Navigator.pop(context);
      _loadCites();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingCite == null 
              ? 'Cité ajoutée avec succès' 
              : 'Cité modifiée avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  void _confirmDelete(Cite cite) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer la cité "${cite.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteCite(cite),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCite(Cite cite) async {
    try {
      await _databaseService.deleteCite(cite.id!);
      Navigator.pop(context);
      _loadCites();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cité supprimée avec succès')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}