import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../services/contacts_service.dart';

class LocatairesScreen extends StatefulWidget {
  const LocatairesScreen({super.key});

  @override
  State<LocatairesScreen> createState() => _LocatairesScreenState();
}

class _LocatairesScreenState extends State<LocatairesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Locataire> _locataires = [];
  List<Cite> _cites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      setState(() {
        _locataires = locataires;
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

  String _getCiteNom(int citeId) {
    final cite = _cites.firstWhere((c) => c.id == citeId, orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()));
    return cite.nom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des Locataires'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locataires.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun locataire enregistré',
                    style: TextStyle(fontSize: 18),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                      itemCount: _locataires.length,
                      itemBuilder: (context, index) {
                        final locataire = _locataires[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text(
                              locataire.nomComplet,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cité: ${_getCiteNom(locataire.citeId)}'),
                                Text('Logement: ${locataire.numeroLogement}'),
                                if (locataire.tarifPersonnalise != null)
                                  Text('Tarif personnalisé: ${locataire.tarifPersonnalise} FCFA'),
                              ],
                            ),
                            isThreeLine: true,
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
                                  _showLocataireDialog(locataire);
                                } else if (value == 'delete') {
                                  _confirmDelete(locataire);
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocataireDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLocataireDialog([Locataire? locataire]) {
    if (_cites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez d\'abord créer au moins une cité')),
      );
      return;
    }

    final nomController = TextEditingController(text: locataire?.nom ?? '');
    final prenomController = TextEditingController(text: locataire?.prenom ?? '');
    final telephoneController = TextEditingController(text: locataire?.telephone ?? '');
    final emailController = TextEditingController(text: locataire?.email ?? '');
    final numeroLogementController = TextEditingController(text: locataire?.numeroLogement ?? '');
    final tarifController = TextEditingController(
      text: locataire?.tarifPersonnalise?.toString() ?? '',
    );
    
    int selectedCiteId = locataire?.citeId ?? _cites.first.id!;
    DateTime selectedDate = locataire?.dateEntree ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locataire == null ? 'Ajouter un locataire' : 'Modifier le locataire'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.contact_page_outlined),
                  label: const Text('Choisir depuis les contacts'),
                  onPressed: () async {
                    final selectedContact = await _selectContact(context);
                    if (selectedContact != null) {
                      final names = ContactsHelper.parseDisplayName(selectedContact.displayName);
                      final phone = ContactsHelper.getContactPhone(selectedContact);
                      final email = ContactsHelper.getContactEmail(selectedContact);

                      setDialogState(() {
                        prenomController.text = names[0];
                        nomController.text = names[1];
                        telephoneController.text = phone;
                        emailController.text = email;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: prenomController,
                  decoration: const InputDecoration(
                    labelText: 'Prénom *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomController,
                  decoration: const InputDecoration(
                    labelText: 'Nom *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCiteId,
                  decoration: const InputDecoration(
                    labelText: 'Cité *',
                    border: OutlineInputBorder(),
                  ),
                  items: _cites.map((cite) => DropdownMenuItem(
                    value: cite.id,
                    child: Text(cite.nom),
                  )).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setDialogState(() => selectedCiteId = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: numeroLogementController,
                  decoration: const InputDecoration(
                    labelText: 'Numéro de logement *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: telephoneController,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tarifController,
                  decoration: const InputDecoration(
                    labelText: 'Tarif personnalisé (FCFA)',
                    border: OutlineInputBorder(),
                    helperText: 'Laisser vide pour utiliser le tarif de base',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Date d\'entrée'),
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
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
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
              child: Text(locataire == null ? 'Ajouter' : 'Modifier'),
            ),
          ],
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
    if (prenom.trim().isEmpty || nom.trim().isEmpty || numeroLogement.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les champs prénom, nom et numéro de logement sont obligatoires')),
      );
      return;
    }

    double? tarifPersonnalise;
    if (tarif.trim().isNotEmpty) {
      tarifPersonnalise = double.tryParse(tarif.trim());
      if (tarifPersonnalise == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le tarif doit être un nombre valide')),
        );
        return;
      }
    }

    try {
      if (existingLocataire == null) {
        // Ajouter nouveau locataire
        final nouveauLocataire = Locataire(
          prenom: prenom.trim(),
          nom: nom.trim(),
          citeId: citeId,
          numeroLogement: numeroLogement.trim(),
          telephone: telephone.trim().isEmpty ? null : telephone.trim(),
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
          telephone: telephone.trim().isEmpty ? null : telephone.trim(),
          email: email.trim().isEmpty ? null : email.trim(),
          tarifPersonnalise: tarifPersonnalise,
          dateEntree: dateEntree,
        );
        await _databaseService.updateLocataire(locataireModifie);
      }

      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingLocataire == null 
              ? 'Locataire ajouté avec succès' 
              : 'Locataire modifié avec succès'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  void _confirmDelete(Locataire locataire) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Text('Êtes-vous sûr de vouloir supprimer le locataire "${locataire.nomComplet}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => _deleteLocataire(locataire),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocataire(Locataire locataire) async {
    try {
      await _databaseService.deleteLocataire(locataire.id!);
      Navigator.pop(context);
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Locataire supprimé avec succès')),
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression: $e')),
      );
    }
  }
}

Future<Contact?> _selectContact(BuildContext context) async {
  final hasPermission = await ContactsHelper.requestContactsPermission();
  if (!hasPermission) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Permission d'accès aux contacts refusée")),
    );
    return null;
  }

  final contacts = await ContactsHelper.getContacts();
  if (contacts.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucun contact trouvé')),
    );
    return null;
  }

  final selectedContact = await showDialog<Contact>(
    context: context,
    builder: (context) => _ContactSelectionDialog(contacts: contacts),
  );

  return selectedContact;
}

class _ContactSelectionDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactSelectionDialog({required this.contacts});

  @override
  State<_ContactSelectionDialog> createState() => _ContactSelectionDialogState();
}

class _ContactSelectionDialogState extends State<_ContactSelectionDialog> {
  late List<Contact> _filteredContacts;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
    _searchController.addListener(_filterContacts);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterContacts);
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = widget.contacts.where((contact) {
        final name = contact.displayName.toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sélectionner un contact'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Rechercher...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ListTile(
                    title: Text(contact.displayName),
                    onTap: () => Navigator.of(context).pop(contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}