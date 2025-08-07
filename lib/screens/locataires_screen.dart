import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import '../models/locataire.dart';
import '../models/cite.dart';
import '../services/database_service.dart';
import '../services/contacts_service.dart';
import '../widgets/modern_app_bar.dart';
import '../widgets/modern_card.dart';
import '../widgets/modern_input.dart';
import '../widgets/modern_list_tile.dart';
import '../widgets/modern_button.dart';
import '../widgets/modern_snackbar.dart';
import '../utils/modern_page_transitions.dart';
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
        _filterLocataires();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ModernSnackBar.showError(
          context,
          'Erreur lors du chargement: $e',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: ModernAppBar(
        title: localizations.locatairesScreenTitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showLocataireDialog(),
            tooltip: localizations.addTenant,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche moderne
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ModernSearchInput(
              hint: localizations.searchTenant,
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterLocataires();
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                  _filterLocataires();
                });
              },
            ),
          ),

          // Statistiques rapides
          if (!_isLoading && _locataires.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ModernCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_locataires.length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Total locataires',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '${_filteredLocataires.length}',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.secondary,
                            ),
                          ),
                          Text(
                            'Affichés',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Liste des locataires
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLocataires.isEmpty
                    ? _buildEmptyState(localizations)
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: _filteredLocataires.length,
                          itemBuilder: (context, index) {
                            final locataire = _filteredLocataires[index];
                            return _buildModernTenantCard(
                                locataire, localizations);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLocataireDialog(),
        icon: const Icon(Icons.person_add_rounded),
        label: Text(localizations.addTenant),
      ),
    );
  }

  Widget _buildEmptyState(dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.people_outline_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isEmpty
                  ? 'Aucun locataire enregistré'
                  : localizations.noLocataireFound,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'Commencez par ajouter votre premier locataire'
                  : 'Essayez avec d\'autres termes de recherche',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 32),
              ModernButton(
                text: localizations.addTenant,
                icon: Icons.person_add_rounded,
                onPressed: () => _showLocataireDialog(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModernTenantCard(Locataire locataire, dynamic localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ModernListTile(
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.person_rounded,
          color: colorScheme.primary,
          size: 24,
        ),
      ),
      title: locataire.nomComplet,
      subtitle: _buildTenantSubtitle(locataire, localizations),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (locataire.tarifPersonnalise != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tarif perso',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.tertiary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () => _showTenantOptions(locataire, localizations),
    );
  }

  String _buildTenantSubtitle(Locataire locataire, dynamic localizations) {
    final citeNom = _getCiteNom(locataire.citeId);
    final parts = <String>[
      'Cité: $citeNom',
      '${localizations.housingNumber}: ${locataire.numeroLogement}',
    ];

    if (locataire.tarifPersonnalise != null) {
      parts.add(
          '${localizations.customRate}: ${locataire.tarifPersonnalise} FCFA');
    }

    return parts.join('\n');
  }

  void _showTenantOptions(Locataire locataire, dynamic localizations) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              locataire.nomComplet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 20),
            ModernListTile(
              leading: const Icon(Icons.history_rounded),
              title: localizations.viewHistory,
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  ModernPageTransitions.slideFromRight(
                    LocataireHistoryScreen(locataire: locataire),
                  ),
                );
              },
            ),
            ModernListTile(
              leading: const Icon(Icons.edit_rounded),
              title: localizations.modify,
              onTap: () {
                Navigator.pop(context);
                _showLocataireDialog(locataire);
              },
            ),
            ModernListTile(
              leading: Icon(Icons.delete_rounded,
                  color: Theme.of(context).colorScheme.error),
              title: localizations.delete,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(locataire);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLocataireDialog([Locataire? locataire]) {
    final localizations = context.l10n;
    if (_cites.isEmpty) {
      ModernSnackBar.showWarning(
        context,
        'Vous devez d\'abord créer une cité avant d\'ajouter un locataire',
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
                ModernButton(
                  text: localizations.chooseFromContacts,
                  icon: Icons.contact_page_outlined,
                  type: ModernButtonType.outline,
                  isFullWidth: true,
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
                ModernInput(
                  label: '${localizations.firstName} *',
                  controller: prenomController,
                ),
                const SizedBox(height: 16),
                ModernInput(
                  label: '${localizations.lastName} *',
                  controller: nomController,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: selectedCiteId,
                  decoration: InputDecoration(
                    labelText: 'Cité *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                ModernInput(
                  label: '${localizations.housingNumber} *',
                  controller: numeroLogementController,
                ),
                const SizedBox(height: 16),
                ModernInput(
                  label: localizations.phone,
                  controller: telephoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                ModernInput(
                  label: localizations.email,
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                ModernInput(
                  label: localizations.customRate,
                  helperText: localizations.leaveEmptyForBaseRate,
                  controller: tarifController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ModernListTile(
                  leading: const Icon(Icons.calendar_today_rounded),
                  title: localizations.entryDate,
                  subtitle: DateFormat('dd/MM/yyyy').format(selectedDate),
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
            ModernButton(
              text: localizations.cancel,
              type: ModernButtonType.ghost,
              onPressed: () => Navigator.pop(context),
            ),
            ModernButton(
              text: locataire == null ? localizations.add : localizations.save,
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
      ModernSnackBar.showError(
        context,
        localizations.firstNameLastNameHousingRequired,
      );
      return;
    }

    double? tarifPersonnalise;
    if (tarif.trim().isNotEmpty) {
      tarifPersonnalise = double.tryParse(tarif.trim());
      if (tarifPersonnalise == null) {
        ModernSnackBar.showError(
          context,
          localizations.invalidRate,
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
      ModernSnackBar.showError(
        context,
        localizations.housingNumberExists(numeroLogement.trim()),
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

      ModernSnackBar.showSuccess(
        context,
        existingLocataire == null
            ? localizations.tenantAddedSuccessfully
            : localizations.tenantModifiedSuccessfully,
      );
    } catch (e) {
      if (!mounted) return;
      ModernSnackBar.showError(
        context,
        '${localizations.errorSavingTenant}: $e',
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
          ModernButton(
            text: localizations.cancel,
            type: ModernButtonType.ghost,
            onPressed: () => Navigator.pop(context),
          ),
          ModernButton(
            text: localizations.delete,
            type: ModernButtonType.danger,
            onPressed: () => _deleteLocataire(locataire),
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

      ModernSnackBar.showSuccess(
        context,
        localizations.tenantDeletedSuccessfully,
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ModernSnackBar.showError(
        context,
        '${localizations.errorDeletingTenant}: $e',
      );
    }
  }

  Future<Contact?> _selectContact(BuildContext context) async {
    final localizations = context.l10n;
    final hasPermission = await ContactsHelper.requestContactsPermission();
    if (!hasPermission) {
      if (context.mounted) {
        ModernSnackBar.showError(
          context,
          localizations.permissionDenied,
        );
      }
      return null;
    }

    final contacts = await ContactsHelper.getContacts();
    if (contacts.isEmpty) {
      if (context.mounted) {
        ModernSnackBar.showInfo(
          context,
          localizations.noContactFound,
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
            ModernSearchInput(
              hint: '${localizations.search}...',
              controller: _searchController,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ModernListTile(
                    leading: const Icon(Icons.person_rounded),
                    title: contact.displayName,
                    onTap: () => Navigator.of(context).pop(contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        ModernButton(
          text: localizations.cancel,
          type: ModernButtonType.ghost,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
