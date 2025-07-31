import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'cites_screen.dart';
import 'locataires_screen.dart';
import 'releves_screen.dart';
import 'configuration_screen.dart';
import '../models/releve.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import '../services/pdf_service.dart';
import '../models/locataire.dart';
import '../models/cite.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseService _databaseService = DatabaseService();
  List<Releve> _monthlyReleves = [];
  List<Locataire> _allLocataires = [];
  List<Cite> _allCites = [];
  Configuration? _configuration;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadMonthlyStats();
  }

  Future<void> _loadMonthlyStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final now = DateTime.now();
      final releves = await _databaseService.getRelevesForMonth(now.month, now.year);
      final locataires = await _databaseService.getLocataires();
      final cites = await _databaseService.getCites();
      final config = await _databaseService.getConfiguration();
      setState(() {
        _monthlyReleves = releves;
        _allLocataires = locataires;
        _allCites = cites;
        _configuration = config;
        _isLoadingStats = false;
      });
    } catch (e) {
      setState(() => _isLoadingStats = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement des stats: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalConsommation = _monthlyReleves.fold(0.0, (sum, item) => sum + item.consommation);
    double totalMontant = _monthlyReleves.fold(0.0, (sum, item) => sum + item.montant);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rentilax Marker'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Statistiques du mois de ${DateFormat.MMMM('fr_FR').format(DateTime.now())}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    _isLoadingStats
                        ? const Center(child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Consommation totale: ${totalConsommation.toStringAsFixed(2)} unités'),
                              Text('Montant total: ${totalMontant.toStringAsFixed(2)} ${_configuration?.devise ?? 'FCFA'}'),
                              if (_monthlyReleves.isEmpty)
                                const Text('Aucun relevé pour ce mois.'),
                            ],
                          ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _monthlyReleves.isEmpty || _configuration == null
                            ? null
                            : () async {
                                final now = DateTime.now();
                                await PdfService.generateMonthlyReport(
                                  releves: _monthlyReleves,
                                  locataires: _allLocataires,
                                  configuration: _configuration!,
                                  cites: _allCites,
                                  month: now.month,
                                  year: now.year,
                                );
                              },
                        icon: const Icon(Icons.print),
                        label: const Text('Imprimer le rapport mensuel'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    'Cités',
                    Icons.location_city,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const CitesScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    'Locataires',
                    Icons.people,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LocatairesScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    'Relevés',
                    Icons.assessment,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RelevesScreen()),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    'Configuration',
                    Icons.settings,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ConfigurationScreen()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color.withOpacity(0.6),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.white,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}