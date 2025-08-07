import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../services/contacts_service.dart';
import 'locataire_history_screen.dart';

class LocatairesScreen extends StatefulWidget {
  const LocatairesScreen({super.key});

  @override
  State<LocatairesScreen> createState() => _LocatairesScreenState();
}

class _LocatairesScreenState extends State<LocatairesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Locataire> _locataires = [];
  List<Locataire> _filteredLocataires = [];
  List<Cite> _cites = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      setState(() {
        _locataires = locataires;
        _cites = cites;
        _filterLocataires(); // Apply initial filter
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

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterLocataires();
    });
  }

  void _filterLocataires() {
    if (_searchQuery.isEmpty) {
      _filteredLocataires = _locataires;
    } else {
      _filteredLocataires = _locataires.where((locataire) {
        final query = _searchQuery.toLowerCase();
        return locataire.nomComplet.toLowerCase().contains(query) ||
            locataire.numeroLogement.toLowerCase().contains(query) ||
            _getCiteNom(locataire.citeId).toLowerCase().contains(query);
      }).toList();
    }
  }

  String _getCiteNom(int citeId) {
    final cite = _cites.firstWhere((c) => c.id == citeId,
        orElse: () => Cite(nom: 'Inconnue', dateCreation: DateTime.now()));
    return cite.nom;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.locatairesScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: localizations.searchTenant,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredLocataires.isEmpty
                  ? Center(
                      child: Text(
                        localizations.noLocataireFound,
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        itemCount: _filteredLocataires.length,
                        itemBuilder: (context, index) {
                          final locataire = _filteredLocataires[index];
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Cité: ${_getCiteNom(locataire.citeId)}'),
                                  Text(
                                      '${localizations.housingNumber}: ${locataire.numeroLogement}'),
                                  if (locataire.tarifPersonnalise != null)
                                    Text(
                                        '${localizations.customRate}: ${locataire.tarifPersonnalise} FCFA'),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'view_history',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.history),
                                        const SizedBox(width: 8),
                                        Text(localizations.viewHistory),
                                      ],
                                    ),
                                  ),
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
                                        const Icon(Icons.delete,
                                            color: Colors.red),
                                        const SizedBox(width: 8),
                                        Text(localizations.delete,
                                            style: const TextStyle(
                                                color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'view_history') {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LocataireHistoryScreen(
                                                locataire: locataire),
                                      ),
                                    );
                                  } else if (value == 'edit') {
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
        ),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLocataireDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showLocataireDialog([Locataire? locataire]) {
    final localizations = context.l10n;
    if (_cites.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.locataireRequired)),
      );
      return;
    }

    final nomController = TextEditingController(text: locataire?.nom ?? '');
    final prenomController =
        TextEditingController(text: locataire?.prenom ?? '');
    final telephoneController =
        TextEditingController(text: locataire?.telephone ?? '');
    final emailController = TextEditingController(text: locataire?.email ?? '');
    final numeroLogementController =
        TextEditingController(text: locataire?.numeroLogement ?? '');
    final tarifController = TextEditingController(
      text: locataire?.tarifPersonnalise?.toString() ?? '',
    );

    int selectedCiteId = locataire?.citeId ?? _cites.first.id!;
    DateTime selectedDate = locataire?.dateEntree ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(locataire == null
              ? localizations.addTenant
              : localizations.editTenant),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton.icon(
                  icon: const Icon(Icons.contact_page_outlined),
                  label: Text(localizations.chooseFromContacts),
                  onPressed: () async {
                    final selectedContact = await _selectContact(context);
                    if (selectedContact != null) {
                      final names = ContactsHelper.parseDisplayName(
                          selectedContact.displayName);
                      final phone =
                          ContactsHelper.getContactPhone(selectedContact);
                      final email =
                          ContactsHelper.getContactEmail(selectedContact);

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
                  decoration: InputDecoration(
                    labelText: '${localizations.firstName} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nomController,
                  decoration: InputDecoration(
                    labelText: '${localizations.lastName} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCiteId,
                  decoration: InputDecoration(
                    labelText: 'Cité *',
                    border: const OutlineInputBorder(),
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
                TextField(
                  controller: numeroLogementController,
                  decoration: InputDecoration(
                    labelText: '${localizations.housingNumber} *',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: telephoneController,
                  decoration: InputDecoration(
                    labelText: localizations.phone,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: localizations.email,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: tarifController,
                  decoration: InputDecoration(
                    labelText: localizations.customRate,
                    border: const OutlineInputBorder(),
                    helperText: localizations.leaveEmptyForBaseRate,
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: Text(localizations.entryDate),
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
              child: Text(localizations.cancel),
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
              child: Text(
                  locataire == null ? localizations.add : localizations.modify),
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
    final localizations = context.l10n;
    if (prenom.trim().isEmpty ||
        nom.trim().isEmpty ||
        numeroLogement.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.firstNameLastNameHousingRequired)),
      );
      return;
    }

    double? tarifPersonnalise;
    if (tarif.trim().isNotEmpty) {
      tarifPersonnalise = double.tryParse(tarif.trim());
      if (tarifPersonnalise == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizations.invalidRate)),
        );
        return;
      }
    }

    // Vérifier l'unicité du numéro de logement dans la cité
    final existingLocataireWithSameNumber =
        await _databaseService.getLocataireByNumeroLogementAndCite(
      numeroLogement.trim(),
      citeId,
      excludeId: existingLocataire?.id,
    );

    if (existingLocataireWithSameNumber != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(localizations.housingNumberExists(numeroLogement.trim()))),
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

      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingLocataire == null
              ? localizations.tenantAddedSuccessfully
              : localizations.tenantModifiedSuccessfully),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorSavingTenant}: $e')),
      );
    }
  }

  void _confirmDelete(Locataire locataire) {
    final localizations = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDeletion),
        content: Text(localizations.confirmDeleteTenant(locataire.nomComplet)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => _deleteLocataire(locataire),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteLocataire(Locataire locataire) async {
    final localizations = context.l10n;
    try {
      await _databaseService.deleteLocataire(locataire.id!);
      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.tenantDeletedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorDeletingTenant}: $e')),
      );
    }
  }
}

Future<Contact?> _selectContact(BuildContext context) async {
  final localizations = context.l10n;
  final hasPermission = await ContactsHelper.requestContactsPermission();
  if (!hasPermission) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.permissionDenied)),
      );
    }
    return null;
  }

  final contacts = await ContactsHelper.getContacts();
  if (contacts.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.noContactFound)),
      );
    }
    return null;
  }

  if (!context.mounted) return null;
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
  State<_ContactSelectionDialog> createState() =>
      _ContactSelectionDialogState();
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
    final localizations = context.l10n;
    return AlertDialog(
      title: Text(localizations.selectContact),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: '${localizations.search}...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
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
          child: Text(localizations.cancel),
        ),
      ],
    );
  }
}
