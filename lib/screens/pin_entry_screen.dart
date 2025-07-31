import 'package:flutter/material.dart';
import '../services/pin_service.dart';

class PinEntryScreen extends StatefulWidget {
  final VoidCallback onPinVerified;

  const PinEntryScreen({super.key, required this.onPinVerified});

  @override
  State<PinEntryScreen> createState() => _PinEntryScreenState();
}

class _PinEntryScreenState extends State<PinEntryScreen> {
  final TextEditingController _pinController = TextEditingController();
  String _errorMessage = '';

  Future<void> _verifyPin() async {
    final isVerified = await PinService.verifyPin(_pinController.text);
    if (isVerified) {
      widget.onPinVerified();
    } else {
      setState(() {
        _errorMessage = 'Code PIN incorrect.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saisir le code PIN'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _pinController,
              decoration: InputDecoration(
                labelText: 'Code PIN',
                border: const OutlineInputBorder(),
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
              ),
              keyboardType: TextInputType.number,
              obscureText: true,
              onSubmitted: (_) => _verifyPin(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyPin,
                child: const Text('Valider'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
