import 'package:flutter/material.dart';
import '../services/pin_service.dart';

class PinSettingsScreen extends StatefulWidget {
  const PinSettingsScreen({super.key});

  @override
  State<PinSettingsScreen> createState() => _PinSettingsScreenState();
}

class _PinSettingsScreenState extends State<PinSettingsScreen> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isPinSet = false;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    _isPinSet = await PinService.isPinSet();
    setState(() {});
  }

  Future<void> _setPin() async {
    if (_pinController.text.isEmpty || _confirmPinController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs.');
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      _showSnackBar('Les codes PIN ne correspondent pas.');
      return;
    }
    if (_pinController.text.length < 4) {
      _showSnackBar('Le code PIN doit contenir au moins 4 chiffres.');
      return;
    }

    await PinService.savePin(_pinController.text);
    _showSnackBar('Code PIN défini avec succès.');
    _pinController.clear();
    _confirmPinController.clear();
    _checkPinStatus();
  }

  Future<void> _changePin() async {
    // For simplicity, we'll just allow setting a new PIN directly.
    // In a real app, you'd ask for the old PIN first.
    await _setPin();
  }

  Future<void> _removePin() async {
    await PinService.deletePin();
    _showSnackBar('Code PIN supprimé avec succès.');
    _checkPinStatus();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres du code PIN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isPinSet)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Définir un code PIN',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    decoration: const InputDecoration(
                      labelText: 'Nouveau code PIN',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPinController,
                    decoration: const InputDecoration(
                      labelText: 'Confirmer le code PIN',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _setPin,
                      child: const Text('Définir le code PIN'),
                    ),
                  ),
                ],
              ),
            if (_isPinSet)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Code PIN actuel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePin,
                      child: const Text('Modifier le code PIN'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _removePin,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Supprimer le code PIN', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
