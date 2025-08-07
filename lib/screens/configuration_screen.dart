import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
import 'package:intl/intl.dart';
import '../models/configuration.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../utils/currencies.dart';
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
          SnackBar(content: Text(context.l10n.errorLoading)),
        );
      }
    }
  }

  Future<void> _saveConfiguration() async {
    final localizations = context.l10n;
    if (_tarifController.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.baseRateRequired)),
      );
      return;
    }

    final double? tarifBase = double.tryParse(_tarifController.text.trim());
    if (tarifBase == null || tarifBase <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.positiveRate)),
      );
      return;
    }

    try {
      final configModifiee = Configuration(
        id: _configuration!.id,
        tarifBase: tarifBase,
        devise: _deviseController.text.trim().isEmpty
            ? 'FCFA'
            : _deviseController.text.trim(),
        dateModification: DateTime.now(),
      );

      await _databaseService.updateConfiguration(configModifiee);

      setState(() => _configuration = configModifiee);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localizations.configurationSavedSuccessfully)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('${localizations.errorSavingConfiguration}: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final localizations = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.configurationScreenTitle),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                          Text(
                            localizations.apparence,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListTile(
                            title: Text(localizations.theme),
                            trailing: DropdownButton<ThemeMode>(
                              value: themeService.themeMode,
                              items: [
                                DropdownMenuItem(
                                  value: ThemeMode.system,
                                  child: Text(localizations.system),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.light,
                                  child: Text(localizations.light),
                                ),
                                DropdownMenuItem(
                                  value: ThemeMode.dark,
                                  child: Text(localizations.dark),
                                ),
                              ],
                              onChanged: (ThemeMode? newMode) {
                                if (newMode != null) {
                                  themeService.setTheme(newMode);
                                }
                              },
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
                          Text(
                            localizations.generalSettings,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          TextField(
                            controller: _tarifController,
                            decoration: InputDecoration(
                              labelText: '${localizations.baseRatePerUnit} *',
                              border: const OutlineInputBorder(),
                              helperText:
                                  'Ce tarif sera appliqué par défaut à tous les locataires',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 16),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              return Autocomplete<Currency>(
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) {
                                  if (textEditingValue.text.isEmpty) {
                                    return const Iterable<Currency>.empty();
                                  }
                                  return currencies.where((Currency option) {
                                    return option
                                        .toString()
                                        .toLowerCase()
                                        .contains(textEditingValue.text
                                            .toLowerCase());
                                  });
                                },
                                displayStringForOption: (Currency option) =>
                                    option.code,
                                fieldViewBuilder: (BuildContext context,
                                    TextEditingController fieldController,
                                    FocusNode fieldFocusNode,
                                    VoidCallback onFieldSubmitted) {
                                  return TextField(
                                    controller: fieldController,
                                    focusNode: fieldFocusNode,
                                    decoration: InputDecoration(
                                      labelText: localizations.currency,
                                      border: const OutlineInputBorder(),
                                      helperText:
                                          localizations.currencyHelperText,
                                    ),
                                  );
                                },
                                onSelected: (Currency selection) {
                                  _deviseController.text = selection.code;
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveConfiguration,
                              child: Text(localizations.saveConfiguration),
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
                          Text(
                            localizations.security,
                            style: const TextStyle(
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
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const PinSettingsScreen()),
                                );
                              },
                              icon: const Icon(Icons.lock),
                              label: Text(localizations.managePinCode),
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
                            Text(
                              localizations.informations,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                                '${localizations.currentRate}: ${_configuration!.tarifBase} ${_configuration!.devise}/unité'),
                            Text(
                                '${localizations.lastModification}: ${DateFormat('dd/MM/yyyy').format(_configuration!.dateModification)}'),
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
                          Text(
                            localizations.about,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(localizations.appVersion),
                          Text(localizations.appDescription),
                          const SizedBox(height: 8),
                          Text(
                            localizations.features,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(localizations.manageCitiesTenants),
                          Text(localizations.automatedReadings),
                          Text(localizations.automaticAmountCalculation),
                          Text(localizations.customizableRates),
                        ],
                      ),
                    ),
                  ),
                  // Espacement en bas pour éviter que le contenu soit coupé
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}
