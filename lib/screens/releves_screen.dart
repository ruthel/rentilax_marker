import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';

class RelevesScreen extends StatefulWidget {
  const RelevesScreen({super.key});

  @override
  State<RelevesScreen> createState() => _RelevesScreenState();
}

class _RelevesScreenState extends State<RelevesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Releve> _releves = [];
  List<Locataire> _locataires = [];
  Configuration? _configuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final releves = await _databaseService.getReleves();
      final locataires = await _databaseService.getLocataires();
      final config = await _databaseService.getConfiguration();
      setState(() {
        _releves = releves;
        _locataires = locataires;
        _configuration = config;
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

  String _getLocataireNom(int locataireId) {
    final locataire = _locataires.firstWhere(
      (l) => l.id == locataireId, 
      orElse: () => Locataire(nom: 'Inconnu', prenom: '', citeId: 0, numeroLogement: '', dateEntree: DateTime.now()),
    );
    return locataire.nomComplet;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Relevés'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _releves.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun relevé enregistré',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                      itemCount: _releves.length,
                      itemBuilder: (context, index) {
                        final releve = _releves[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.assessment),
                            ),
                            title: Text(
                              _getLocataireNom(releve.locataireId),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}'),
                                Text('Consommation: ${releve.consommation.toStringAsFixed(2)} unités'),
                                Text('Montant: ${releve.montant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}'),
                              ],
                            ),
                            isThreeLine: true,
                            trailing: PopupMenuButton(
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'view',
                                  child: Row(
                                    children: [
                                      Icon(Icons.visibility),
                                      SizedBox(width: 8),
                                      Text('Voir détails'),
                                    ],
                                  ),
                                ),
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
                                if (value == 'view') {
                                  _showReleveDetails(releve);
                                } else if (value == 'edit') {
                                  _showReleveDialog(releve);
                                } else if (value == 'delete') {
                                  _confirmDelete(releve);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReleveDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showReleveDetails(Releve releve) {
    final locataire = _locataires.firstWhere((l) => l.id == releve.locataireId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du relevé'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Locataire: ${locataire.nomComplet}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Date: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}'),
            const SizedBox(height: 8),
            Text('Ancien index: ${releve.ancienIndex.toStringAsFixed(2)}'),
            Text('Nouvel index: ${releve.nouvelIndex.toStringAsFixed(2)}'),
            Text('Consommation: ${releve.consommation.toStringAsFixed(2)} unités'),
            const SizedBox(height: 8),
            Text('Tarif appliqué: ${releve.tarif.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}/unité'),
            Text('Montant total: ${releve.montant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}', 
                 style: const TextStyle(fontWeight: FontWeight.bold)),
            if (releve.commentaire != null && releve.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Commentaire: ${releve.commentaire}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showReleveDialog([Releve? releve]) async {
    if (_locataires.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord créer au moins un locataire')),
      );
      return;
    }

    final ancienIndexController = TextEditingController(text: releve?.ancienIndex.toString() ?? '');
    final nouvelIndexController = TextEditingController(text: releve?.nouvelIndex.toString() ?? '');
    final commentaireController = TextEditingController(text: releve?.commentaire ?? '');
    
    int selectedLocataireId = releve?.locataireId ?? _locataires.first.id!;
    DateTime selectedDate = releve?.dateReleve ?? DateTime.now();

    // Si c'est un nouveau relevé, récupérer le dernier index du locataire
    if (releve == null) {
      final dernierReleve = await _databaseService.getDernierReleve(selectedLocataireId);
      if (dernierReleve != null) {
        ancienIndexController.text = dernierReleve.nouvelIndex.toString();
      } else {
        // Si aucun relevé précédent, initialiser à 0
        ancienIndexController.text = '0';
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(releve == null ? 'Nouveau relevé' : 'Modifier le relevé'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<int>(
                  value: selectedLocataireId,
                  decoration: const InputDecoration(
                    labelText: 'Locataire *',
                    border: OutlineInputBorder(),
                  ),
                  items: _locataires.map((locataire) => DropdownMenuItem(
                    value: locataire.id,
                    child: Text(locataire.nomComplet),
                  )).toList(),
                  onChanged: releve == null ? (value) async {
                    if (value != null) {
                      setDialogState(() => selectedLocataireId = value);
                      // Récupérer le dernier index pour ce locataire
                      final dernierReleve = await _databaseService.getDernierReleve(value);
                      if (dernierReleve != null) {
                        ancienIndexController.text = dernierReleve.nouvelIndex.toString();
                      } else {
                        ancienIndexController.text = '0';
                      }
                    }
                  } : null,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: ancienIndexController,
                  decoration: const InputDecoration(
                    labelText: 'Ancien index *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  readOnly: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nouvelIndexController,
                  decoration: const InputDecoration(
                    labelText: 'Nouvel index *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date du relevé'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                  decoration: const InputDecoration(
                    labelText: 'Commentaire (optionnel)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => _saveReleve(
                releve,
                selectedLocataireId,
                ancienIndexController.text,
                nouvelIndexController.text,
                selectedDate,
                commentaireController.text,
              ),
              child: Text(releve == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveReleve(
    Releve? existingReleve,
    int locataireId,
    String ancienIndex,
    String nouvelIndex,
    DateTime dateReleve,
    String commentaire,
  ) async {
    if (ancienIndex.trim().isEmpty || nouvelIndex.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les index sont obligatoires')),
      );
      return;
    }

    final double? ancienIndexValue = double.tryParse(ancienIndex.trim());
    final double? nouvelIndexValue = double.tryParse(nouvelIndex.trim());

    if (ancienIndexValue == null || nouvelIndexValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les index doivent être des nombres valides')),
      );
      return;
    }

    if (nouvelIndexValue <= ancienIndexValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nouvel index doit être supérieur à l\'ancien index')),
      );
      return;
    }

    try {
      // Déterminer le tarif à utiliser
      final locataire = _locataires.firstWhere((l) => l.id == locataireId);
      final tarif = locataire.tarifPersonnalise ?? _configuration!.tarifBase;

      if (existingReleve == null) {
        // Vérifier si un relevé existe déjà pour ce locataire et ce mois
        final existingMonthlyReleve = await _databaseService.getReleveForLocataireAndMonth(
          locataireId,
          dateReleve.month,
          dateReleve.year,
        );
        if (existingMonthlyReleve != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Un relevé existe déjà pour ce locataire pour le mois de ${DateFormat.MMMM('fr_FR').format(dateReleve)}')),
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
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
        );
        await _databaseService.insertReleve(nouveauReleve);
      } else {
        // Modifier relevé existant
        final releveModifie = Releve(
          id: existingReleve.id,
          locataireId: locataireId,
          ancienIndex: ancienIndexValue,
          nouvelIndex: nouvelIndexValue,
          tarif: tarif,
          dateReleve: dateReleve,
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
        );
        await _databaseService.updateReleve(releveModifie);
      }

      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingReleve == null 
              ? 'Relevé ajouté avec succès' 
              : 'Relevé modifié avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  void _confirmDelete(Releve releve) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Êtes-vous sûr de vouloir supprimer ce relevé ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteReleve(releve),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReleve(Releve releve) async {
    try {
      await _databaseService.deleteReleve(releve.id!);
      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relevé supprimé avec succès')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}