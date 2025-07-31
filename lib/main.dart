import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'services/pin_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const RentilaxMarkerApp());
}

class RentilaxMarkerApp extends StatefulWidget {
  const RentilaxMarkerApp({super.key});

  @override
  State<RentilaxMarkerApp> createState() => _RentilaxMarkerAppState();
}

class _RentilaxMarkerAppState extends State<RentilaxMarkerApp> {
  bool _isPinSet = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    _isPinSet = await PinService.isPinSet();
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Rentilax Marker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: _isPinSet
          ? PinEntryScreen(onPinVerified: () {
              setState(() {
                _isPinSet = false; // Once verified, don't show PIN screen again until app restart
              });
            })
          : const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
