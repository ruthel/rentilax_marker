import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'services/advanced_notification_service.dart';
import 'widgets/modern_splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuration du mode immersif complet
  await _configureImmersiveMode();

  // Initialisation des services
  await initializeDateFormatting('fr_FR', null);
  tz.initializeTimeZones();
  await EnhancedNotificationService.initialize();
  await AdvancedNotificationService.initialize();

  runApp(const RentilaxTrackerApp());
}

Future<void> _configureImmersiveMode() async {
  // Mode immersif edge-to-edge complet (barres masquées)
  await SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
    overlays: [],
  );

  // Configuration des couleurs de la barre de statut et navigation
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Forcer l'orientation portrait pour une expérience optimale
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
}

class RentilaxTrackerApp extends StatelessWidget {
  const RentilaxTrackerApp({super.key});

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
            title: 'Rentilax Tracker',
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
            theme: ThemeService.lightTheme.copyWith(
              // Configuration pour le mode immersif
              appBarTheme: ThemeService.lightTheme.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.dark,
                ),
              ),
            ),
            darkTheme: ThemeService.darkTheme.copyWith(
              // Configuration pour le mode immersif en thème sombre
              appBarTheme: ThemeService.darkTheme.appBarTheme.copyWith(
                systemOverlayStyle: const SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: Brightness.light,
                ),
              ),
            ),
            themeMode: themeService.themeMode,
            home: const ImmersiveWrapper(child: InitialScreen()),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}

class ImmersiveWrapper extends StatelessWidget {
  final Widget child;

  const ImmersiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: Theme.of(context).brightness == Brightness.dark
          ? const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.light,
            )
          : const SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
              statusBarBrightness: Brightness.light,
              systemNavigationBarColor: Colors.transparent,
              systemNavigationBarIconBrightness: Brightness.dark,
            ),
      child: child,
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

    return targetScreen;
  }
}
