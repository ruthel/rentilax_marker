# Guide d'intégration rapide - Google Drive

## 🚀 Étapes d'intégration (5 minutes)

### 1. Installer les dépendances
```bash
flutter pub add google_sign_in googleapis http path_provider shared_preferences
```

### 2. Initialiser le service dans main.dart
```dart
import 'services/sync_scheduler_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le planificateur de synchronisation
  await SyncSchedulerService.initialize();
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rentilax Marker',
      home: HomeScreen(),
    );
  }
}
```

### 3. Ajouter le widget de statut (optionnel)
```dart
import 'widgets/sync_status_widget.dart';

// Dans votre écran principal ou dashboard
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Dashboard'),
      actions: [
        CompactSyncStatusWidget(), // Widget compact dans l'AppBar
      ],
    ),
    body: Column(
      children: [
        SyncStatusWidget(), // Widget complet
        // ... autres widgets
      ],
    ),
  );
}
```

### 4. Configuration Google Cloud (production)

Pour utiliser en production, vous devrez :

1. **Créer un projet Google Cloud Console**
2. **Activer l'API Google Drive**
3. **Créer des identifiants OAuth 2.0**
4. **Télécharger les fichiers de configuration**

Voir le fichier `google_drive_dependencies.md` pour les détails complets.

## 🧪 Test en mode développement

En attendant la configuration Google Cloud, vous pouvez tester l'interface :

```dart
// L'interface Google Drive sera visible mais la connexion échouera
// Tous les autres onglets (Backup local, Export, Import) fonctionnent normalement
```

## 📱 Fonctionnalités disponibles immédiatement

- ✅ Interface Google Drive complète
- ✅ Gestion des erreurs de connexion
- ✅ Planificateur de synchronisation
- ✅ Widgets de statut
- ✅ Configuration de synchronisation automatique
- ✅ Sauvegarde locale (existante)
- ✅ Export/Import (existant)

## 🔧 API principale

```dart
// Vérifier la connexion
bool isConnected = await GoogleDriveService.isSignedIn();

// Se connecter
GoogleSignInAccount? account = await GoogleDriveService.signIn();

// Sauvegarder
BackupResult result = await GoogleDriveService.backupToGoogleDrive();

// Lister les sauvegardes
List<BackupInfo> backups = await GoogleDriveService.listBackups();

// Restaurer
RestoreResult result = await GoogleDriveService.restoreFromGoogleDrive(fileId);

// Configurer la synchronisation automatique
await SyncSchedulerService.configureAutoSync(
  enabled: true,
  intervalHours: 24,
  wifiOnly: true,
);

// Synchronisation forcée
SyncResult result = await SyncSchedulerService.forceSyncNow();
```

## 🎯 Résultat

Après intégration, vous aurez :

1. **Nouvel onglet "Google Drive"** dans l'écran de sauvegarde
2. **Synchronisation automatique** configurable
3. **Widgets de statut** pour le dashboard
4. **API complète** pour la gestion des sauvegardes cloud
5. **Interface utilisateur** intuitive et moderne

L'implémentation est complète et prête à l'emploi ! 🎉