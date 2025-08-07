// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Rentilax Marker';

  @override
  String get citesScreenTitle => 'Gestion des Cités';

  @override
  String get locatairesScreenTitle => 'Gestion des Locataires';

  @override
  String get relevesScreenTitle => 'Gestion des Relevés';

  @override
  String get configurationScreenTitle => 'Configuration';

  @override
  String get noRelevesRecorded => 'Aucun relevé enregistré';

  @override
  String get totalConsumption => 'Fasture Totale';

  @override
  String get totalAmount => 'Montant Total';

  @override
  String get noReadingsForThisMonth => 'Aucun relevé pour ce mois.';

  @override
  String get printMonthlyReport => 'Imprimer le Rapport Mensuel';

  @override
  String get cities => 'Cités';

  @override
  String get tenants => 'Locataires';

  @override
  String get readings => 'Relevés';

  @override
  String get configuration => 'Configuration';

  @override
  String get addCity => 'Ajouter une Cité';

  @override
  String get editCity => 'Modifier la Cité';

  @override
  String get cityName => 'Nom de la Cité';

  @override
  String get address => 'Adresse';

  @override
  String get cancel => 'Annuler';

  @override
  String get add => 'Ajouter';

  @override
  String get save => 'Enregistrer';

  @override
  String get modify => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get close => 'Fermer';

  @override
  String get cityAddedSuccessfully => 'Cité ajoutée avec succès';

  @override
  String get cityModifiedSuccessfully => 'Cité modifiée avec succès';

  @override
  String get errorSavingCity => 'Erreur lors de l\'enregistrement de la cité';

  @override
  String get confirmDeletion => 'Confirmer la Suppression';

  @override
  String get cityDeletedSuccessfully => 'Cité supprimée avec succès';

  @override
  String get errorDeletingCity => 'Erreur lors de la suppression de la cité';

  @override
  String get cityRequired => 'Le nom de la cité est requis';

  @override
  String get noCitiesRecorded => 'Aucune cité enregistrée';

  @override
  String confirmDeleteCity(String cityName) {
    return 'Êtes-vous sûr de vouloir supprimer la cité \"$cityName\" ?';
  }

  @override
  String get noTenantsRecorded => 'Aucun locataire enregistré';

  @override
  String get addTenant => 'Ajouter un Locataire';

  @override
  String get editTenant => 'Modifier le Locataire';

  @override
  String get chooseFromContacts => 'Choisir dans les contacts';

  @override
  String get firstName => 'Prénom';

  @override
  String get lastName => 'Nom';

  @override
  String get housingNumber => 'Numéro de Logement';

  @override
  String get phone => 'Téléphone';

  @override
  String get email => 'Email';

  @override
  String get customRate => 'Tarif Personnalisé (FCFA)';

  @override
  String get leaveEmptyForBaseRate =>
      'Laisser vide pour utiliser le tarif de base';

  @override
  String get entryDate => 'Date d\'Entrée';

  @override
  String get tenantAddedSuccessfully => 'Locataire ajouté avec succès';

  @override
  String get tenantModifiedSuccessfully => 'Locataire modifié avec succès';

  @override
  String get errorSavingTenant =>
      'Erreur lors de l\'enregistrement du locataire';

  @override
  String get firstNameLastNameHousingRequired =>
      'Le prénom, nom et numéro de logement sont requis';

  @override
  String get invalidRate => 'Le tarif doit être un nombre valide';

  @override
  String get tenantDeletedSuccessfully => 'Locataire supprimé avec succès';

  @override
  String get errorDeletingTenant =>
      'Erreur lors de la suppression du locataire';

  @override
  String get noLocataireFound => 'Aucun locataire trouvé';

  @override
  String housingNumberExists(String housingNumber) {
    return 'Le numéro de logement \"$housingNumber\" existe déjà dans cette cité';
  }

  @override
  String confirmDeleteTenant(String tenantName) {
    return 'Êtes-vous sûr de vouloir supprimer le locataire \"$tenantName\" ?';
  }

  @override
  String get viewHistory => 'Voir l\'Historique';

  @override
  String historyOf(String tenantName) {
    return 'Historique de $tenantName';
  }

  @override
  String get noReadingsRecordedForThisTenant =>
      'Aucun relevé enregistré pour ce locataire';

  @override
  String get readingMonth => 'Mois du Relevé';

  @override
  String get creationDate => 'Date de Création';

  @override
  String get consumption => 'Consommation';

  @override
  String get amount => 'Montant';

  @override
  String get status => 'Statut';

  @override
  String get paid => 'Payé';

  @override
  String get unpaid => 'Impayé';

  @override
  String get on => 'le';

  @override
  String get viewDetails => 'Voir les Détails';

  @override
  String get markAsUnpaid => 'Marquer comme impayé';

  @override
  String get markAsPaid => 'Marquer comme payé';

  @override
  String get readingDetails => 'Détails du Relevé';

  @override
  String get tenant => 'Locataire';

  @override
  String get oldIndex => 'Ancien Index';

  @override
  String get newIndex => 'Nouvel Index';

  @override
  String get appliedRate => 'Tarif Appliqué';

  @override
  String get comment => 'Commentaire';

  @override
  String get paymentStatus => 'Statut de Paiement';

  @override
  String get paymentDate => 'Date de Paiement';

  @override
  String get newReading => 'Nouveau Relevé';

  @override
  String get modifyReading => 'Modifier le Relevé';

  @override
  String get locataireRequired =>
      'Veuillez créer au moins un locataire d\'abord';

  @override
  String get indexesRequired => 'Les index sont requis';

  @override
  String get indexesMustBeValidNumbers =>
      'Les index doivent être des nombres valides';

  @override
  String get newIndexGreaterThanOldIndex =>
      'Le nouvel index doit être supérieur à l\'ancien index';

  @override
  String readingAlreadyExists(String month) {
    return 'Un relevé existe déjà pour ce locataire pour le mois de $month';
  }

  @override
  String get readingAddedSuccessfully => 'Relevé ajouté avec succès';

  @override
  String get readingModifiedSuccessfully => 'Relevé modifié avec succès';

  @override
  String get errorSavingReading => 'Erreur lors de l\'enregistrement du relevé';

  @override
  String get confirmDeleteReading =>
      'Êtes-vous sûr de vouloir supprimer ce relevé ?';

  @override
  String get readingDeletedSuccessfully => 'Relevé supprimé avec succès';

  @override
  String get errorDeletingReading => 'Erreur lors de la suppression du relevé';

  @override
  String get readingMarkedAsPaid => 'Relevé marqué comme payé';

  @override
  String get readingMarkedAsUnpaid => 'Relevé marqué comme impayé';

  @override
  String get errorUpdatingPaymentStatus =>
      'Erreur lors de la mise à jour du statut de paiement';

  @override
  String get apparence => 'Apparence';

  @override
  String get theme => 'Thème';

  @override
  String get system => 'Système';

  @override
  String get light => 'Clair';

  @override
  String get dark => 'Sombre';

  @override
  String get generalSettings => 'Paramètres Généraux';

  @override
  String get baseRatePerUnit => 'Tarif de base par unité';

  @override
  String get currency => 'Devise';

  @override
  String get currencyHelperText =>
      'Devise utilisée pour les calculs (ex: FCFA, EUR, USD)';

  @override
  String get saveConfiguration => 'Enregistrer la Configuration';

  @override
  String get security => 'Sécurité';

  @override
  String get managePinCode => 'Gérer le Code PIN';

  @override
  String get informations => 'Informations';

  @override
  String get currentRate => 'Tarif actuel';

  @override
  String get lastModification => 'Dernière modification';

  @override
  String get about => 'À propos';

  @override
  String get appVersion => 'Rentilax Marker v1.0.0';

  @override
  String get appDescription =>
      'Application de gestion des relevés de consommation';

  @override
  String get features => 'Fonctionnalités :';

  @override
  String get manageCitiesTenants => '• Gestion des cités et locataires';

  @override
  String get automatedReadings => '• Relevés de consommation automatisés';

  @override
  String get automaticAmountCalculation => '• Calcul automatique des montants';

  @override
  String get customizableRates => '• Tarifs personnalisables par locataire';

  @override
  String get baseRateRequired => 'Le tarif de base est requis';

  @override
  String get positiveRate => 'Le tarif doit être un nombre positif';

  @override
  String get configurationSavedSuccessfully =>
      'Configuration enregistrée avec succès';

  @override
  String get errorSavingConfiguration =>
      'Erreur lors de l\'enregistrement de la configuration';

  @override
  String get pinSettings => 'Paramètres PIN';

  @override
  String get setPinCode => 'Définir le Code PIN';

  @override
  String get currentPin => 'PIN Actuel';

  @override
  String get newPin => 'Nouveau PIN';

  @override
  String get confirmNewPin => 'Confirmer le Nouveau PIN';

  @override
  String get changePin => 'Changer le PIN';

  @override
  String get pinCodeSetSuccessfully => 'Code PIN défini avec succès';

  @override
  String get pinCodeChangedSuccessfully => 'Code PIN modifié avec succès';

  @override
  String get pinCodeRemovedSuccessfully => 'Code PIN supprimé avec succès';

  @override
  String get errorSettingPinCode => 'Erreur lors de la définition du code PIN';

  @override
  String get errorChangingPinCode =>
      'Erreur lors de la modification du code PIN';

  @override
  String get errorRemovingPinCode =>
      'Erreur lors de la suppression du code PIN';

  @override
  String get pinCodeRequired => 'Le code PIN est requis';

  @override
  String get pinCodeMustBe5Digits => 'Le code PIN doit contenir 5 chiffres';

  @override
  String get pinCodesDoNotMatch => 'Les codes PIN ne correspondent pas';

  @override
  String get incorrectCurrentPin => 'PIN actuel incorrect';

  @override
  String get enterYourPin => 'Entrez votre PIN pour accéder à l\'application';

  @override
  String get incorrectPin => 'PIN incorrect';

  @override
  String get pleaseEnter5DigitsPin => 'Veuillez entrer un PIN à 5 chiffres';

  @override
  String get unlock => 'Déverrouiller';

  @override
  String get searchTenant => 'Rechercher un locataire...';

  @override
  String get searchReading => 'Rechercher un relevé...';

  @override
  String get paymentStatusFilter => 'Statut de Paiement';

  @override
  String get all => 'Tous';

  @override
  String get cityFilter => 'Cité';

  @override
  String get allCities => 'Toutes les Cités';

  @override
  String get monthFilter => 'Mois';

  @override
  String get allMonths => 'Tous les Mois';

  @override
  String get noTenantFound => 'Aucun locataire trouvé';

  @override
  String get noRelevesFound => 'Aucun relevé trouvé';

  @override
  String get errorLoadingHistory =>
      'Erreur lors du chargement de l\'historique';

  @override
  String get errorLoadingStats => 'Erreur lors du chargement des statistiques';

  @override
  String get errorLoading => 'Erreur lors du chargement';

  @override
  String get permissionDenied => 'Permission refusée';

  @override
  String get noContactFound => 'Aucun contact trouvé';

  @override
  String get selectContact => 'Sélectionner un contact';

  @override
  String get search => 'Rechercher...';

  @override
  String get totalPaidAmount => 'Total Payé';

  @override
  String get totalUnpaidAmount => 'Total Impayé';

  @override
  String get units => 'unités';

  @override
  String get unit => 'unité';

  @override
  String get optional => 'optionnel';

  @override
  String get unknown => 'Inconnu';

  @override
  String get receiptOfConsumption => 'Reçu de Consommation';

  @override
  String get city => 'Cité';

  @override
  String get log => 'Journal';

  @override
  String get month => 'Mois';

  @override
  String get createdOn => 'Créé le';

  @override
  String get note => 'Note';

  @override
  String get consumptionReport => 'Rapport de Consommation';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String generatedOn(String date) {
    return 'Généré le $date';
  }

  @override
  String totalReadings(int count) {
    return 'Total des relevés : $count';
  }
}
