import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter_localizations/flutter_localizations.dart';
import 'l10n/generated/app_localizations.dart';

import 'screens/home_screen.dart';
import 'screens/pin_entry_screen.dart';
import 'services/pin_service.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';
import 'services/enhanced_notification_service.dart';
import 'widgets/modern_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialisation des services
  await initializeDateFormatting('fr_FR', null);
  tz.initializeTimeZones();
  await EnhancedNotificationService.initialize();

  runApp(const RentilaxMarkerApp());
}

class RentilaxMarkerApp extends StatelessWidget {
  const RentilaxMarkerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeService()),
        ChangeNotifierProvider(create: (_) => LanguageService()),
      ],
      child: Consumer2<ThemeService, LanguageService>(
        builder: (context, themeService, languageService, child) {
          return MaterialApp(
            title: 'Rentilax Marker',
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('fr'), // French
            ],
            locale: languageService.currentLocale,
            theme: ThemeService.lightTheme,
            darkTheme: ThemeService.darkTheme,
            themeMode: themeService.themeMode,
            home: const InitialScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isPinSet = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    _isPinSet = await PinService.isPinSet();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final targetScreen = _isPinSet
        ? PinEntryScreen(onPinVerified: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          })
        : const HomeScreen();

    return ModernSplashScreen(
      title: 'Rentilax Marker',
      subtitle: 'Gestion moderne des locataires',
      duration: const Duration(seconds: 2),
      child: targetScreen,
    );
  }
}
