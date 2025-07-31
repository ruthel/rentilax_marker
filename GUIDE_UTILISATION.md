# Guide d'Utilisation - Rentilax Marker

## 🚀 Démarrage Rapide

### 1. Configuration Initiale
- Ouvrez l'application
- Allez dans **Configuration** (icône engrenage)
- Définissez le **tarif de base** (ex: 100 FCFA par unité)
- Choisissez votre **devise** (FCFA par défaut)
- Cliquez sur **Sauvegarder**

### 2. Créer des Cités
- Allez dans **Cités** (icône bâtiment)
- Cliquez sur le bouton **+**
- Saisissez le nom de la cité (obligatoire)
- Ajoutez l'adresse (optionnel)
- Cliquez sur **Ajouter**

### 3. Ajouter des Locataires
- Allez dans **Locataires** (icône personnes)
- Cliquez sur le bouton **+**
- Remplissez les informations :
  - **Prénom et Nom** (obligatoires)
  - **Cité** (sélectionner dans la liste)
  - **Numéro de logement** (obligatoire)
  - **Téléphone et Email** (optionnels)
  - **Tarif personnalisé** (optionnel, sinon utilise le tarif de base)
  - **Date d'entrée**
- Cliquez sur **Ajouter**

### 4. Faire des Relevés
- Allez dans **Relevés** (icône graphique)
- Cliquez sur le bouton **+**
- Sélectionnez le **locataire**
- L'**ancien index** se remplit automatiquement (dernier relevé)
- Saisissez le **nouvel index**
- Choisissez la **date du relevé**
- Ajoutez un **commentaire** si nécessaire
- Cliquez sur **Ajouter**

## 📊 Calculs Automatiques

L'application calcule automatiquement :
- **Consommation** = Nouvel index - Ancien index
- **Montant** = Consommation × Tarif (personnalisé ou de base)

## 🔧 Fonctionnalités Avancées

### Tarifs Personnalisés
- Chaque locataire peut avoir son propre tarif
- Si pas de tarif personnalisé → utilise le tarif de base
- Modifiable à tout moment dans les informations du locataire

### Historique des Relevés
- Tous les relevés sont conservés
- Consultation des détails via le menu contextuel
- Modification possible des relevés existants

### Gestion des Données
- **Modifier** : Menu contextuel (3 points) → Modifier
- **Supprimer** : Menu contextuel (3 points) → Supprimer
- **Voir détails** : Menu contextuel (3 points) → Voir détails (relevés)

## 💡 Conseils d'Utilisation

### Premier Relevé
- Pour le premier relevé d'un locataire, l'ancien index peut être 0
- Ou la valeur du compteur au moment de l'installation

### Relevés Réguliers
- L'ancien index est automatiquement rempli
- Vérifiez toujours la cohérence des index
- Le nouvel index doit être supérieur à l'ancien

### Organisation
- Créez d'abord toutes vos cités
- Ajoutez ensuite tous vos locataires
- Commencez les relevés de manière régulière

## 🛠️ Résolution de Problèmes

### "Veuillez d'abord créer au moins une cité"
- Allez dans Cités et créez au moins une cité

### "Veuillez d'abord créer au moins un locataire"
- Allez dans Locataires et créez au moins un locataire

### "Le nouvel index doit être supérieur à l'ancien index"
- Vérifiez que vous avez saisi le bon nouvel index
- L'index ne peut pas diminuer (sauf cas exceptionnel de remise à zéro)

### Erreur de calcul
- Vérifiez les tarifs dans Configuration
- Vérifiez le tarif personnalisé du locataire si applicable

## 📱 Navigation

- **Écran d'accueil** : 4 cartes pour accéder aux fonctions principales
- **Retour** : Bouton retour en haut à gauche de chaque écran
- **Actions** : Menu 3 points sur chaque élément de liste
- **Ajout** : Bouton + flottant en bas à droite

## 💾 Sauvegarde

Toutes les données sont automatiquement sauvegardées dans la base de données locale de l'application.