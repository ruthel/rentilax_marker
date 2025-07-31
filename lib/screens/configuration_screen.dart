import 'package:flutter/material.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import '../utils/currencies.dart';
import 'pin_settings_screen.dart';
import 'pin_settings_screen.dart';

class ConfigurationScreen extends StatefulWidget {
  const ConfigurationScreen({super.key});

  @override
  State<ConfigurationScreen> createState() => _ConfigurationScreenState();
}

class _ConfigurationScreenState extends State<ConfigurationScreen> {
  final DatabaseService _databaseService = DatabaseService();
  final _tarifController = TextEditingController();
  final _deviseController = TextEditingController();
  Configuration? _configuration;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _tarifController.dispose();
    _deviseController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    setState(() => _isLoading = true);
    try {
      final config = await _databaseService.getConfiguration();
      setState(() {
        _configuration = config;
        _tarifController.text = config.tarifBase.toString();
        _deviseController.text = config.devise;
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

  Future<void> _saveConfiguration() async {
    if (_tarifController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le tarif de base est obligatoire')),
      );
      return;
    }

    final double? tarifBase = double.tryParse(_tarifController.text.trim());
    if (tarifBase == null || tarifBase <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le tarif doit être un nombre positif')),
      );
      return;
    }

    try {
      final configModifiee = Configuration(
        id: _configuration!.id,
        tarifBase: tarifBase,
        devise: _deviseController.text.trim().isEmpty ? 'FCFA' : _deviseController.text.trim(),
        dateModification: DateTime.now(),
      );

      await _databaseService.updateConfiguration(configModifiee);
      
      setState(() => _configuration = configModifiee);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuration sauvegardée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Paramètres généraux',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _tarifController,
                            decoration: const InputDecoration(
                              labelText: 'Tarif de base par unité *',
                              border: OutlineInputBorder(),
                              helperText: 'Ce tarif sera appliqué par défaut à tous les locataires',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          Autocomplete<Currency>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              if (textEditingValue.text.isEmpty) {
                                return const Iterable<Currency>.empty();
                              }
                              return currencies.where((Currency option) {
                                return option.toString().toLowerCase().contains(textEditingValue.text.toLowerCase());
                              });
                            },
                            displayStringForOption: (Currency option) => option.code,
                            fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                              return TextField(
                                controller: fieldController,
                                focusNode: fieldFocusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Devise',
                                  border: OutlineInputBorder(),
                                  helperText: 'Devise utilisée pour les calculs (ex: FCFA, EUR, USD)',
                                ),
                              );
                            },
                            onSelected: (Currency selection) {
                              _deviseController.text = selection.code;
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveConfiguration,
                              child: const Text('Sauvegarder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sécurité',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const PinSettingsScreen()),
                                );
                              },
                              icon: const Icon(Icons.lock),
                              label: const Text('Gérer le code PIN'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_configuration != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Informations',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Tarif actuel: ${_configuration!.tarifBase} ${_configuration!.devise}/unité'),
                            Text('Dernière modification: ${_configuration!.dateModification.day}/${_configuration!.dateModification.month}/${_configuration!.dateModification.year}'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'À propos',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text('Rentilax Marker v1.0.0'),
                          Text('Application de gestion des relevés de consommation'),
                          SizedBox(height: 8),
                          Text(
                            'Fonctionnalités:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('• Gestion des cités et locataires'),
                          Text('• Relevés de consommation automatisés'),
                          Text('• Calcul automatique des montants'),
                          Text('• Tarifs personnalisables par locataire'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}