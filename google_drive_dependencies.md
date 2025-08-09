## Utilisation

```dart
import 'package:rentilax_marker/services/google_drive_service.dart';

// Se connecter à Google Drive
final account = await GoogleDriveService.signIn();

// Sauvegarder sur Google Drive
final result = await GoogleDriveService.backupToGoogleDrive();

// Lister les sauvegardes
final backups = await GoogleDriveService.listBackups();

// Restaurer depuis Google Drive
final restoreResult = await GoogleDriveService.restoreFromGoogleDrive(fileId);
```

## Fonctionnalités disponibles

- ✅ Connexion/Déconnexion Google
- ✅ Sauvegarde automatique sur Google Drive
- ✅ Liste des sauvegardes disponibles
- ✅ Restauration depuis Google Drive
- ✅ Synchronisation automatique configurable
- ✅ Suppression de sauvegardes
- ✅ Métadonnées de sauvegarde (timestamp, taille, etc.)
- ✅ Gestion des erreurs et feedback utilisateur
- ✅ Interface utilisateur intégrée dans l'écran de sauvegarde