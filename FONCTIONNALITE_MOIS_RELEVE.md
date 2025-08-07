# Fonctionnalité : Spécification du Mois de Relevé

## Description

Cette fonctionnalité permet aux utilisateurs de spécifier le mois auquel appartient une relevé lors de sa création, indépendamment de la date de création de la relevé. Cela répond au besoin de pouvoir créer une relevé de juin en juillet, par exemple.

## Utilisation

### Création d'une nouvelle relevé

1. **Accéder à l'écran des relevés** : Depuis l'écran principal, naviguez vers "Gestion des Relevés"

2. **Créer une nouvelle relevé** : Appuyez sur le bouton "+" (FloatingActionButton)

3. **Remplir les informations** :
   - **Locataire** : Sélectionnez le locataire concerné
   - **Mois de la relevé** : Sélectionnez le mois auquel appartient cette relevé (par défaut : mois courant)
   - **Ancien index** : Saisissez l'ancien index (pré-rempli avec le dernier index du locataire)
   - **Nouvel index** : Saisissez le nouvel index
   - **Date de création** : Date de création de la relevé (par défaut : aujourd'hui)
   - **Commentaire** : Commentaire optionnel

4. **Validation** : Le système vérifie qu'aucune relevé n'existe déjà pour ce locataire et ce mois de relevé

### Modification d'une relevé existante

1. **Accéder aux détails** : Dans la liste des relevés, appuyez sur le menu (⋮) d'une relevé

2. **Modifier** : Sélectionnez "Modifier"

3. **Changer le mois** : Vous pouvez modifier le mois de la relevé si nécessaire

4. **Validation** : Le système vérifie les conflits lors du changement de mois

### Affichage des informations

- **Liste des relevés** : Affiche le mois de relevé en premier, suivi de la date de création
- **Détails d'une relevé** : Affiche clairement le mois de relevé et la date de création séparément

## Exemples d'utilisation

### Cas 1 : Relevé normale
- **Mois de relevé** : Janvier 2024
- **Date de création** : 31 janvier 2024
- **Résultat** : Relevé de janvier créée en janvier

### Cas 2 : Relevé en retard
- **Mois de relevé** : Juin 2024
- **Date de création** : 15 juillet 2024
- **Résultat** : Relevé de juin créée en juillet

### Cas 3 : Relevé anticipée
- **Mois de relevé** : Mars 2024
- **Date de création** : 25 février 2024
- **Résultat** : Relevé de mars créée en février

## Règles de validation

1. **Unicité** : Un seul relevé par locataire et par mois de relevé
2. **Index croissants** : Le nouvel index doit être supérieur à l'ancien index
3. **Champs obligatoires** : Locataire, mois de relevé, ancien index, nouvel index

## Messages d'erreur

- **"Un relevé existe déjà pour ce locataire pour le mois de [mois]"** : Tentative de création d'un doublon
- **"Les index sont obligatoires"** : Champs index vides
- **"Les index doivent être des nombres valides"** : Format d'index incorrect
- **"Le nouvel index doit être supérieur à l'ancien index"** : Logique d'index incorrecte

## Migration des données

- Les relevés existants conservent leur fonctionnement
- Le mois de relevé est automatiquement défini à la date de création pour les relevés existants
- Aucune perte de données lors de la mise à jour

## Avantages

1. **Flexibilité** : Possibilité de créer des relevés pour des mois antérieurs ou futurs
2. **Clarté** : Distinction claire entre le mois de la relevé et la date de création
3. **Organisation** : Meilleure organisation des relevés par période
4. **Traçabilité** : Conservation de l'historique de création des relevés

## Compatibilité

- Compatible avec toutes les fonctionnalités existantes
- Les rapports et exports utilisent le mois de relevé pour le regroupement
- L'interface utilisateur reste intuitive et familière