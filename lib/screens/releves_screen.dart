import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import 'package:rentilax_marker/models/unit_type.dart';
import 'package:rentilax_marker/services/unit_service.dart';
import '../models/cite.dart';
import '../models/releve.dart';
import '../models/locataire.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import 'payment_management_screen.dart';

class RelevesScreen extends StatefulWidget {
  const RelevesScreen({super.key});

  @override
  State<RelevesScreen> createState() => _RelevesScreenState();
}

class _RelevesScreenState extends State<RelevesScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final UnitService _unitService = UnitService();
  List<Releve> _allReleves = []; // All relevés loaded from DB
  List<Releve> _filteredReleves = []; // Relevés displayed after filtering
  List<Locataire> _locataires = [];
  List<Cite> _cites = []; // Add cites for filtering
  List<ConsumptionUnit> _availableUnits = [];
  Configuration? _configuration;
  bool _isLoading = true;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool? _filterIsPaid; // null: all, true: paid, false: unpaid
  int? _filterCiteId; // null: all, int: specific cite
  DateTime? _filterMonth; // null: all, DateTime: specific month

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
      final releves = await _databaseService.getReleves();
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();
      final units = await _unitService.getAllUnits();
      setState(() {
        _allReleves = releves;
        _locataires = locataires;
        _cites = cites;
        _configuration = config;
        _availableUnits = units;
        _isLoading = false;
      });
      _filterReleves(); // Apply initial filter
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.l10n.errorLoading}: $e')),
        );
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _filterReleves();
    });
  }

  void _filterReleves() {
    List<Releve> filteredList = _allReleves;

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filteredList = filteredList.where((releve) {
        final locataire =
            _locataires.firstWhere((l) => l.id == releve.locataireId);
        final query = _searchQuery.toLowerCase();
        return locataire.nomComplet.toLowerCase().contains(query) ||
            locataire.numeroLogement.toLowerCase().contains(query) ||
            releve.commentaire?.toLowerCase().contains(query) == true;
      }).toList();
    }

    // Filter by payment status
    if (_filterIsPaid != null) {
      filteredList = filteredList
          .where((releve) => releve.isPaid == _filterIsPaid)
          .toList();
    }

    // Filter by cite
    if (_filterCiteId != null) {
      filteredList = filteredList.where((releve) {
        final locataire =
            _locataires.firstWhere((l) => l.id == releve.locataireId);
        return locataire.citeId == _filterCiteId;
      }).toList();
    }

    // Filter by month
    if (_filterMonth != null) {
      filteredList = filteredList.where((releve) {
        return releve.moisReleve.year == _filterMonth!.year &&
            releve.moisReleve.month == _filterMonth!.month;
      }).toList();
    }

    setState(() {
      _filteredReleves = filteredList;
    });
  }

  String _getLocataireNom(int locataireId) {
    final locataire = _locataires.firstWhere(
      (l) => l.id == locataireId,
      orElse: () => Locataire(
          nom: 'Inconnu',
          prenom: '',
          citeId: 0,
          numeroLogement: '',
          dateEntree: DateTime.now()),
    );
    return locataire.nomComplet;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.relevesScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: localizations.searchReading,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.search),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                SizedBox(
                  width: 150, // Fixed width for payment status filter
                  child: DropdownButtonFormField<bool?>(
                    value: _filterIsPaid,
                    decoration: InputDecoration(
                      labelText: localizations.paymentStatusFilter,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(localizations.all)),
                      DropdownMenuItem(
                          value: true, child: Text(localizations.paid)),
                      DropdownMenuItem(
                          value: false, child: Text(localizations.unpaid)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterIsPaid = value;
                        _filterReleves();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150, // Fixed width for city filter
                  child: DropdownButtonFormField<int?>(
                    value: _filterCiteId,
                    decoration: InputDecoration(
                      labelText: localizations.cityFilter,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(localizations.allCities)),
                      ..._cites.map((cite) => DropdownMenuItem(
                            value: cite.id,
                            child: Flexible(child: Text(cite.nom)),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _filterCiteId = value;
                        _filterReleves();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 150, // Fixed width for month filter
                  child: ListTile(
                    title: Text(localizations.monthFilter),
                    subtitle: Text(_filterMonth == null
                        ? localizations.allMonths
                        : DateFormat('MMMM yyyy', localizations.localeName)
                            .format(_filterMonth!)),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _filterMonth ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          _filterMonth = DateTime(date.year, date.month, 1);
                          _filterReleves();
                        });
                      } else {
                        setState(() {
                          _filterMonth = null;
                          _filterReleves();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredReleves.isEmpty
                  ? Center(
                      child: Text(
                        localizations.noRelevesFound,
                        style: const TextStyle(fontSize: 18),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.builder(
                        itemCount: _filteredReleves.length,
                        itemBuilder: (context, index) {
                          final releve = _filteredReleves[index];
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
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      '${localizations.readingMonth}: ${DateFormat('MMMM yyyy', localizations.localeName).format(releve.moisReleve)}'),
                                  Text(
                                      '${localizations.creationDate}: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}'),
                                  Text(
                                      '${localizations.consumption}: ${_formatConsumptionWithUnit(releve)}'),
                                  Text(
                                      '${localizations.amount}: ${releve.montant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}'),
                                  if (releve.isPartiallyPaid)
                                    Text(
                                      'Payé: ${releve.paidAmount.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'} (${releve.paymentProgress.toStringAsFixed(1)}%)',
                                      style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  Row(
                                    children: [
                                      Text('${localizations.status}: '),
                                      Icon(
                                        releve.isPaid
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: releve.isPaid
                                            ? Colors.green
                                            : Colors.red,
                                        size: 16,
                                      ),
                                      Text(
                                        releve.isPaid
                                            ? ' ${localizations.paid}'
                                            : ' ${localizations.unpaid}',
                                        style: TextStyle(
                                          color: releve.isPaid
                                              ? Colors.green
                                              : Colors.red,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (releve.isPaid &&
                                          releve.paymentDate != null)
                                        Text(
                                            ' ${localizations.on} ${DateFormat('dd/MM/yyyy').format(releve.paymentDate!)}'),
                                    ],
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  if (!releve.isPaid ||
                                      releve.remainingAmount > 0)
                                    PopupMenuItem(
                                      value: 'manage_payment',
                                      child: Row(
                                        children: [
                                          const Icon(Icons.payment,
                                              color: Colors.blue),
                                          const SizedBox(width: 8),
                                          Text(releve.isPartiallyPaid
                                              ? 'Compléter Paiement'
                                              : 'Gérer Paiement'),
                                        ],
                                      ),
                                    ),
                                  PopupMenuItem(
                                    value: 'toggle_payment',
                                    child: Row(
                                      children: [
                                        Icon(releve.isPaid
                                            ? Icons.cancel_outlined
                                            : Icons.check_circle_outline),
                                        const SizedBox(width: 8),
                                        Text(releve.isPaid
                                            ? localizations.markAsUnpaid
                                            : localizations.markAsPaid),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'view',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.visibility),
                                        const SizedBox(width: 8),
                                        Text(localizations.viewDetails),
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
                                  if (value == 'manage_payment') {
                                    _navigateToPaymentManagement(releve);
                                  } else if (value == 'toggle_payment') {
                                    _togglePaymentStatus(releve);
                                  } else if (value == 'view') {
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
        )
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showReleveDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showReleveDetails(Releve releve) {
    final localizations = context.l10n;
    final locataire = _locataires.firstWhere((l) => l.id == releve.locataireId);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.readingDetails),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${localizations.tenant}: ${locataire.nomComplet}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
                '${localizations.readingMonth}: ${DateFormat('MMMM yyyy', localizations.localeName).format(releve.moisReleve)}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(
                '${localizations.creationDate}: ${DateFormat('dd/MM/yyyy').format(releve.dateReleve)}'),
            const SizedBox(height: 8),
            Text(
                '${localizations.oldIndex}: ${releve.ancienIndex.toStringAsFixed(2)}'),
            Text(
                '${localizations.newIndex}: ${releve.nouvelIndex.toStringAsFixed(2)}'),
            Text(
                '${localizations.consumption}: ${_formatConsumptionWithUnit(releve)}'),
            const SizedBox(height: 8),
            Text(
                '${localizations.appliedRate}: ${releve.tarif.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}/${localizations.unit}'),
            Text(
                '${localizations.totalAmount}: ${releve.montant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            if (releve.commentaire != null &&
                releve.commentaire!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('${localizations.comment}: ${releve.commentaire}'),
            ],
            const SizedBox(height: 8),
            Text(
              '${localizations.paymentStatus}: ${releve.isPaid ? localizations.paid : localizations.unpaid}',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: releve.isPaid ? Colors.green : Colors.red),
            ),
            if (releve.isPaid && releve.paymentDate != null)
              Text(
                  '${localizations.paymentDate}: ${DateFormat('dd/MM/yyyy').format(releve.paymentDate!)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  void _showReleveDialog([Releve? releve]) async {
    final localizations = context.l10n;
    if (_locataires.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.locataireRequired)),
      );
      return;
    }

    final ancienIndexController =
        TextEditingController(text: releve?.ancienIndex.toString() ?? '');
    final nouvelIndexController =
        TextEditingController(text: releve?.nouvelIndex.toString() ?? '');
    final commentaireController =
        TextEditingController(text: releve?.commentaire ?? '');

    int selectedLocataireId = releve?.locataireId ?? _locataires.first.id!;
    DateTime selectedDate = releve?.dateReleve ?? DateTime.now();
    DateTime selectedMoisReleve = releve?.moisReleve ?? DateTime.now();

    // Sélection d'unité
    ConsumptionUnit? selectedUnit;
    if (releve?.unitId != null) {
      selectedUnit = await _unitService.getUnitById(releve!.unitId!);
    } else {
      // Utiliser l'unité par défaut selon la configuration
      selectedUnit = await _unitService.getDefaultUnitForType(
          _configuration?.defaultUnitType ?? UnitType.water);
    }

    // Si c'est un nouveau relevé, récupérer le dernier index du locataire
    if (releve == null) {
      final dernierReleve =
          await _databaseService.getDernierReleve(selectedLocataireId);
      if (dernierReleve != null) {
        ancienIndexController.text = dernierReleve.nouvelIndex.toString();
      } else {
        // Si aucun relevé précédent, initialiser à 0
        ancienIndexController.text = '0';
      }
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(releve == null
              ? localizations.newReading
              : localizations.modifyReading),
          content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height *
                  0.6, // Limit height to 60% of screen height
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedLocataireId,
                      decoration: InputDecoration(
                        labelText: '${localizations.tenant} *',
                        border: const OutlineInputBorder(),
                      ),
                      items: _locataires
                          .map((locataire) => DropdownMenuItem(
                                value: locataire.id,
                                child: Text(locataire.nomComplet),
                              ))
                          .toList(),
                      onChanged: releve == null
                          ? (value) async {
                              if (value != null) {
                                setDialogState(
                                    () => selectedLocataireId = value);
                                // Récupérer le dernier index pour ce locataire
                                final dernierReleve = await _databaseService
                                    .getDernierReleve(value);
                                if (dernierReleve != null) {
                                  ancienIndexController.text =
                                      dernierReleve.nouvelIndex.toString();
                                } else {
                                  ancienIndexController.text = '0';
                                }
                              }
                            }
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: ancienIndexController,
                      decoration: InputDecoration(
                        labelText: '${localizations.oldIndex} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nouvelIndexController,
                      decoration: InputDecoration(
                        labelText: '${localizations.newIndex} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ConsumptionUnit>(
                      value: selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unité de mesure *',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableUnits
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _getUnitTypeColor(unit.type)
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        unit.symbol,
                                        style: TextStyle(
                                          color: _getUnitTypeColor(unit.type),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(unit.name),
                                          Text(
                                            unit.type.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() => selectedUnit = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text('${localizations.readingMonth} *'),
                      subtitle: Text(
                          DateFormat('MMMM yyyy', localizations.localeName)
                              .format(selectedMoisReleve)),
                      trailing: const Icon(Icons.calendar_month),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedMoisReleve,
                          firstDate: DateTime(2000),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setDialogState(() => selectedMoisReleve =
                              DateTime(date.year, date.month, 1));
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      title: Text(localizations.creationDate),
                      subtitle:
                          Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
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
                      decoration: InputDecoration(
                        labelText:
                            '${localizations.comment} (${localizations.optional})',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () => _saveReleve(
                releve,
                selectedLocataireId,
                ancienIndexController.text,
                nouvelIndexController.text,
                selectedDate,
                selectedMoisReleve,
                commentaireController.text,
                selectedUnit,
              ),
              child: Text(
                  releve == null ? localizations.add : localizations.modify),
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
    DateTime moisReleve,
    String commentaire,
    ConsumptionUnit? selectedUnit,
  ) async {
    final localizations = context.l10n;
    if (ancienIndex.trim().isEmpty || nouvelIndex.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.indexesRequired)),
      );
      return;
    }

    final double? ancienIndexValue = double.tryParse(ancienIndex.trim());
    final double? nouvelIndexValue = double.tryParse(nouvelIndex.trim());

    if (ancienIndexValue == null || nouvelIndexValue == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.indexesMustBeValidNumbers)),
      );
      return;
    }

    if (nouvelIndexValue <= ancienIndexValue) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.newIndexGreaterThanOldIndex)),
      );
      return;
    }

    try {
      // Déterminer le tarif à utiliser
      final locataire = _locataires.firstWhere((l) => l.id == locataireId);
      final tarif = locataire.tarifPersonnalise ?? _configuration!.tarifBase;

      if (existingReleve == null) {
        // Vérifier si un relevé existe déjà pour ce locataire et ce mois de relevé
        final existingMonthlyReleve =
            await _databaseService.getReleveForLocataireAndMonth(
          locataireId,
          moisReleve.month,
          moisReleve.year,
        );
        if (existingMonthlyReleve != null) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(localizations.readingAlreadyExists(
                    DateFormat.MMMM('fr_FR').format(moisReleve)))),
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
          moisReleve: moisReleve,
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
          unitId: selectedUnit?.id,
          unitType: selectedUnit?.type ?? UnitType.water,
        );
        await _databaseService.insertReleve(nouveauReleve);
      } else {
        // Vérifier si le nouveau mois de relevé n'entre pas en conflit (sauf si c'est le même relevé)
        if (existingReleve.moisReleve.month != moisReleve.month ||
            existingReleve.moisReleve.year != moisReleve.year) {
          final conflictReleve =
              await _databaseService.getReleveForLocataireAndMonth(
            locataireId,
            moisReleve.month,
            moisReleve.year,
          );
          if (conflictReleve != null &&
              conflictReleve.id != existingReleve.id) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(localizations.readingAlreadyExists(
                      DateFormat.MMMM('fr_FR').format(moisReleve)))),
            );
            return;
          }
        }

        // Modifier relevé existant
        final releveModifie = Releve(
          id: existingReleve.id,
          locataireId: locataireId,
          ancienIndex: ancienIndexValue,
          nouvelIndex: nouvelIndexValue,
          tarif: tarif,
          dateReleve: dateReleve,
          moisReleve: moisReleve,
          commentaire: commentaire.trim().isEmpty ? null : commentaire.trim(),
          isPaid: existingReleve.isPaid, // Conserver le statut de paiement
          paymentDate:
              existingReleve.paymentDate, // Conserver la date de paiement
          paidAmount: existingReleve.paidAmount, // Conserver le montant payé
          unitId: selectedUnit?.id,
          unitType: selectedUnit?.type ?? existingReleve.unitType,
        );
        await _databaseService.updateReleve(releveModifie);
      }

      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingReleve == null
              ? localizations.readingAddedSuccessfully
              : localizations.readingModifiedSuccessfully),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorSavingReading}: $e')),
      );
    }
  }

  void _confirmDelete(Releve releve) {
    final localizations = context.l10n;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.confirmDeletion),
        content: Text(localizations.confirmDeleteReading),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(localizations.cancel),
          ),
          ElevatedButton(
            onPressed: () => _deleteReleve(releve),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(localizations.delete,
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReleve(Releve releve) async {
    final localizations = context.l10n;
    try {
      await _databaseService.deleteReleve(releve.id!);
      if (!mounted) return;
      Navigator.pop(context);
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.readingDeletedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${localizations.errorDeletingReading}: $e')),
      );
    }
  }

  Future<void> _togglePaymentStatus(Releve releve) async {
    final localizations = context.l10n;
    try {
      final newIsPaid = !releve.isPaid;
      final newPaymentDate = newIsPaid ? DateTime.now() : null;

      await _databaseService.updatePaymentStatus(
        releve.id!,
        newIsPaid,
        newPaymentDate,
      );
      if (!mounted) return;
      _loadData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newIsPaid
                ? localizations.readingMarkedAsPaid
                : localizations.readingMarkedAsUnpaid,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${localizations.errorUpdatingPaymentStatus}: $e')),
      );
    }
  }

  Future<void> _navigateToPaymentManagement(Releve releve) async {
    final locataire = _locataires.firstWhere((l) => l.id == releve.locataireId);

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentManagementScreen(
          releve: releve,
          locataire: locataire,
        ),
      ),
    );

    // Recharger les données si un paiement a été effectué
    if (result == true) {
      _loadData();
    }
  }

  Color _getUnitTypeColor(UnitType type) {
    switch (type) {
      case UnitType.water:
        return Colors.blue;
      case UnitType.electricity:
        return Colors.amber;
      case UnitType.gas:
        return Colors.orange;
    }
  }

  String _formatConsumptionWithUnit(Releve releve) {
    if (releve.unitId != null) {
      final unit =
          _availableUnits.where((u) => u.id == releve.unitId).firstOrNull;
      if (unit != null) {
        return '${releve.consommation.toStringAsFixed(2)} ${unit.symbol}';
      }
    }
    // Fallback vers l'unité par type
    return '${releve.consommation.toStringAsFixed(2)} ${_getUnitSymbolByType(releve.unitType)}';
  }

  String _getUnitSymbolByType(UnitType type) {
    switch (type) {
      case UnitType.water:
        return 'm³';
      case UnitType.electricity:
        return 'kWh';
      case UnitType.gas:
        return 'm³';
    }
  }
}
