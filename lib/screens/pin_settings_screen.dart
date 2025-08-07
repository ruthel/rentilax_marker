import 'package:flutter/material.dart';
import 'package:rentilax_marker/l10n/l10n_extensions.dart';
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
    final localizations = context.l10n;
    if (_pinController.text.isEmpty || _confirmPinController.text.isEmpty) {
      _showSnackBar(localizations.pinCodeRequired);
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      _showSnackBar(localizations.pinCodesDoNotMatch);
      return;
    }
    if (_pinController.text.length != 5) {
      _showSnackBar(localizations.pinCodeMustBe5Digits);
      return;
    }

    try {
      await PinService.savePin(_pinController.text);
      _showSnackBar(localizations.pinCodeSetSuccessfully);
      _pinController.clear();
      _confirmPinController.clear();
      _checkPinStatus();
    } catch (e) {
      _showSnackBar('${localizations.errorSettingPinCode}: $e');
    }
  }

  Future<void> _changePin() async {
    final localizations = context.l10n;
    if (_pinController.text.isEmpty || _confirmPinController.text.isEmpty) {
      _showSnackBar(localizations.pinCodeRequired);
      return;
    }
    if (_pinController.text != _confirmPinController.text) {
      _showSnackBar(localizations.pinCodesDoNotMatch);
      return;
    }
    if (_pinController.text.length != 5) {
      _showSnackBar(localizations.pinCodeMustBe5Digits);
      return;
    }

    try {
      await PinService.savePin(_pinController.text);
      _showSnackBar(localizations.pinCodeChangedSuccessfully);
      _pinController.clear();
      _confirmPinController.clear();
      _checkPinStatus();
    } catch (e) {
      _showSnackBar('${localizations.errorChangingPinCode}: $e');
    }
  }

  Future<void> _removePin() async {
    final localizations = context.l10n;
    try {
      await PinService.deletePin();
      _showSnackBar(localizations.pinCodeRemovedSuccessfully);
      _checkPinStatus();
    } catch (e) {
      _showSnackBar('${localizations.errorRemovingPinCode}: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.pinSettings),
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
                  Text(
                    localizations.setPinCode,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
                    decoration: InputDecoration(
                      labelText: localizations.newPin,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _confirmPinController,
                    decoration: InputDecoration(
                      labelText: localizations.confirmNewPin,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _setPin,
                      child: Text(localizations.setPinCode),
                    ),
                  ),
                ],
              ),
            if (_isPinSet)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.currentPin,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _changePin,
                      child: Text(localizations.changePin),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _removePin,
                      style:
                          ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: Text(localizations.delete,
                          style: const TextStyle(color: Colors.white)),
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
