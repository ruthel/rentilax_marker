# Rentilax Marker

Application Flutter pour gérer les locataires et leurs relevés de consommation.

## Fonctionnalités

### 🏢 Gestion des Cités
- Ajouter, modifier et supprimer des cités
- Chaque cité peut avoir un nom et une adresse
- Organisation des locataires par cité

### 👥 Gestion des Locataires
- Enregistrement des informations des locataires (nom, prénom, contact)
- Attribution d'un numéro de logement
- Possibilité de définir un tarif personnalisé par locataire
- Classement par cité

### 📊 Relevés de Consommation
- Saisie des anciens et nouveaux index
- Calcul automatique de la consommation (nouvel index - ancien index)
- Calcul automatique du montant (consommation × tarif)
- Historique des relevés par locataire
- Utilisation du tarif personnalisé du locataire ou du tarif de base

### ⚙️ Configuration
- Définition du tarif de base pour tous les locataires
- Personnalisation de la devise
- Interface de configuration simple

## Structure de l'Application

```
lib/
├── main.dart                    # Point d'entrée de l'application
├── models/                      # Modèles de données
│   ├── cite.dart               # Modèle pour les cités
│   ├── locataire.dart          # Modèle pour les locataires
│   ├── releve.dart             # Modèle pour les relevés
│   └── configuration.dart      # Modèle pour la configuration
├── services/                    # Services
│   └── database_service.dart   # Service de base de données SQLite
└── screens/                     # Écrans de l'application
    ├── home_screen.dart        # Écran d'accueil
    ├── cites_screen.dart       # Gestion des cités
    ├── locataires_screen.dart  # Gestion des locataires
    ├── releves_screen.dart     # Gestion des relevés
    └── configuration_screen.dart # Configuration
```

## Base de Données

L'application utilise SQLite avec les tables suivantes :

- **cites** : Stockage des cités
- **locataires** : Informations des locataires
- **releves** : Historique des relevés de consommation
- **configuration** : Paramètres de l'application

## Installation et Utilisation

### Prérequis
- Flutter SDK
- Dart SDK
- Android Studio ou VS Code avec les extensions Flutter

### Installation
1. Cloner le projet
2. Installer les dépendances :
   ```bash
   flutter pub get
   ```
3. Lancer l'application :
   ```bash
   flutter run
   ```

### Première utilisation
1. Configurer le tarif de base dans les paramètres
2. Créer au moins une cité
3. Ajouter des locataires à la cité
4. Commencer à saisir les relevés

## Dépendances

- `sqflite` : Base de données SQLite
- `path` : Gestion des chemins de fichiers
- `intl` : Formatage des dates et nombres

## Fonctionnement des Relevés

1. **Premier relevé** : L'ancien index peut être saisi manuellement (généralement 0)
2. **Relevés suivants** : L'ancien index est automatiquement rempli avec le nouvel index du relevé précédent
3. **Calcul automatique** : 
   - Consommation = Nouvel index - Ancien index
   - Montant = Consommation × Tarif (personnalisé ou de base)

## Tarification

- **Tarif de base** : Défini dans la configuration, appliqué à tous les locataires par défaut
- **Tarif personnalisé** : Peut être défini individuellement pour chaque locataire
- **Priorité** : Le tarif personnalisé prime sur le tarif de base

## Interface Utilisateur

L'application propose une interface intuitive avec :
- Écran d'accueil avec navigation par cartes
- Listes avec actions contextuelles (modifier, supprimer)
- Formulaires de saisie avec validation
- Affichage des détails des relevés
- Configuration centralisée

## Version

Version 1.0.0 - Application de gestion des relevés de consommation pour locataires