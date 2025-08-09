# Guide d'intégration du service de notifications avancées

## Configuration dans main.dart

Pour utiliser le service de notifications avec navigation, vous devez configurer la clé de navigation globale dans votre fichier `main.dart` :

```dart
import 'package:flutter/material.dart';
import 'services/advanced_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service de notifications
  await AdvancedNotificationService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Créer une clé de navigation globale
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Configurer la clé de navigation pour le service de notifications
    AdvancedNotificationService.setNavigatorKey(navigatorKey);

    return MaterialApp(
      title: 'Rentilax Marker',
      navigatorKey: navigatorKey, // Important : utiliser la clé ici
      home: HomeScreen(),
      // ... autres configurations
    );
  }
}
```

## Utilisation des notifications

### 1. Programmer un rappel de relevé
```dart
await AdvancedNotificationService.scheduleReadingReminder(
  locataireId: 123,
  locataireName: 'Jean Dupont',
  scheduledDate: DateTime.now().add(Duration(days: 1)),
);
```

### 2. Programmer une notification de paiement en retard
```dart
await AdvancedNotificationService.schedulePaymentDueNotification(
  locataireId: 123,
  locataireName: 'Jean Dupont',
  amount: 15000.0,
  dueDate: DateTime.now().subtract(Duration(days: 5)),
);
```

### 3. Afficher une notification instantanée
```dart
await AdvancedNotificationService.showInstantNotification(
  title: 'Nouveau relevé ajouté',
  body: 'Le relevé de Jean Dupont a été enregistré avec succès',
  type: NotificationType.success,
);
```

## Navigation automatique

Quand l'utilisateur tape sur une notification :

- **Rappel de relevé** → Navigue vers l'écran des relevés avec un message contextuel
- **Paiement en retard** → Navigue vers la gestion des paiements du relevé concerné
- **Rapport mensuel** → Navigue vers le dashboard avancé

## Gestion des permissions

Le service demande automatiquement les permissions nécessaires lors de l'initialisation. Assurez-vous d'avoir configuré les permissions dans :

### Android (`android/app/src/main/AndroidManifest.xml`)
```xml
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.WAKE_LOCK" />
```

### iOS (`ios/Runner/Info.plist`)
```xml
<key>UIBackgroundModes</key>
<array>
    <string>background-processing</string>
</array>
```

## Test de la navigation

Vous pouvez tester la navigation depuis l'interface avec :

```dart
// Tester la navigation vers les relevés
AdvancedNotificationService.testNotificationNavigation('reading_reminder', '123');

// Tester la navigation vers les paiements
AdvancedNotificationService.testNotificationNavigation('payment_due', '123');

// Tester la navigation vers le rapport
AdvancedNotificationService.testNotificationNavigation('monthly_report', '12');
```