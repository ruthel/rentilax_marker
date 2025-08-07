import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `context.l10n`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Rentilax Marker'**
  String get appTitle;

  /// Title for the cities management screen
  ///
  /// In en, this message translates to:
  /// **'Manage Cities'**
  String get citesScreenTitle;

  /// Title for the tenants management screen
  ///
  /// In en, this message translates to:
  /// **'Manage Tenants'**
  String get locatairesScreenTitle;

  /// Title for the readings management screen
  ///
  /// In en, this message translates to:
  /// **'Manage Readings'**
  String get relevesScreenTitle;

  /// Title for the configuration screen
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configurationScreenTitle;

  /// No description provided for @noRelevesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No readings recorded'**
  String get noRelevesRecorded;

  /// No description provided for @totalConsumption.
  ///
  /// In en, this message translates to:
  /// **'Total Consumption'**
  String get totalConsumption;

  /// No description provided for @totalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get totalAmount;

  /// No description provided for @noReadingsForThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No readings for this month.'**
  String get noReadingsForThisMonth;

  /// No description provided for @printMonthlyReport.
  ///
  /// In en, this message translates to:
  /// **'Print Monthly Report'**
  String get printMonthlyReport;

  /// No description provided for @cities.
  ///
  /// In en, this message translates to:
  /// **'Cities'**
  String get cities;

  /// No description provided for @tenants.
  ///
  /// In en, this message translates to:
  /// **'Tenants'**
  String get tenants;

  /// No description provided for @readings.
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get readings;

  /// No description provided for @configuration.
  ///
  /// In en, this message translates to:
  /// **'Configuration'**
  String get configuration;

  /// No description provided for @addCity.
  ///
  /// In en, this message translates to:
  /// **'Add City'**
  String get addCity;

  /// No description provided for @editCity.
  ///
  /// In en, this message translates to:
  /// **'Edit City'**
  String get editCity;

  /// No description provided for @cityName.
  ///
  /// In en, this message translates to:
  /// **'City Name'**
  String get cityName;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @modify.
  ///
  /// In en, this message translates to:
  /// **'Modify'**
  String get modify;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @cityAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'City added successfully'**
  String get cityAddedSuccessfully;

  /// No description provided for @cityModifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'City modified successfully'**
  String get cityModifiedSuccessfully;

  /// No description provided for @errorSavingCity.
  ///
  /// In en, this message translates to:
  /// **'Error saving city'**
  String get errorSavingCity;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @cityDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'City deleted successfully'**
  String get cityDeletedSuccessfully;

  /// No description provided for @errorDeletingCity.
  ///
  /// In en, this message translates to:
  /// **'Error deleting city'**
  String get errorDeletingCity;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'City name is required'**
  String get cityRequired;

  /// No description provided for @noCitiesRecorded.
  ///
  /// In en, this message translates to:
  /// **'No cities recorded'**
  String get noCitiesRecorded;

  /// Confirmation message for deleting a city
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete city \"{cityName}\"?'**
  String confirmDeleteCity(String cityName);

  /// No description provided for @noTenantsRecorded.
  ///
  /// In en, this message translates to:
  /// **'No tenants recorded'**
  String get noTenantsRecorded;

  /// No description provided for @addTenant.
  ///
  /// In en, this message translates to:
  /// **'Add Tenant'**
  String get addTenant;

  /// No description provided for @editTenant.
  ///
  /// In en, this message translates to:
  /// **'Edit Tenant'**
  String get editTenant;

  /// No description provided for @chooseFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Choose from contacts'**
  String get chooseFromContacts;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @housingNumber.
  ///
  /// In en, this message translates to:
  /// **'Housing Number'**
  String get housingNumber;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @customRate.
  ///
  /// In en, this message translates to:
  /// **'Custom Rate (FCFA)'**
  String get customRate;

  /// No description provided for @leaveEmptyForBaseRate.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use base rate'**
  String get leaveEmptyForBaseRate;

  /// No description provided for @entryDate.
  ///
  /// In en, this message translates to:
  /// **'Entry Date'**
  String get entryDate;

  /// No description provided for @tenantAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tenant added successfully'**
  String get tenantAddedSuccessfully;

  /// No description provided for @tenantModifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tenant modified successfully'**
  String get tenantModifiedSuccessfully;

  /// No description provided for @errorSavingTenant.
  ///
  /// In en, this message translates to:
  /// **'Error saving tenant'**
  String get errorSavingTenant;

  /// No description provided for @firstNameLastNameHousingRequired.
  ///
  /// In en, this message translates to:
  /// **'First name, last name and housing number are required'**
  String get firstNameLastNameHousingRequired;

  /// No description provided for @invalidRate.
  ///
  /// In en, this message translates to:
  /// **'Rate must be a valid number'**
  String get invalidRate;

  /// No description provided for @tenantDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Tenant deleted successfully'**
  String get tenantDeletedSuccessfully;

  /// No description provided for @errorDeletingTenant.
  ///
  /// In en, this message translates to:
  /// **'Error deleting tenant'**
  String get errorDeletingTenant;

  /// No description provided for @noLocataireFound.
  ///
  /// In en, this message translates to:
  /// **'No tenant found'**
  String get noLocataireFound;

  /// Error message when housing number already exists
  ///
  /// In en, this message translates to:
  /// **'Housing number \"{housingNumber}\" already exists in this city'**
  String housingNumberExists(String housingNumber);

  /// Confirmation message for deleting a tenant
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete tenant \"{tenantName}\"?'**
  String confirmDeleteTenant(String tenantName);

  /// No description provided for @viewHistory.
  ///
  /// In en, this message translates to:
  /// **'View History'**
  String get viewHistory;

  /// Title for tenant history screen
  ///
  /// In en, this message translates to:
  /// **'History of {tenantName}'**
  String historyOf(String tenantName);

  /// No description provided for @noReadingsRecordedForThisTenant.
  ///
  /// In en, this message translates to:
  /// **'No readings recorded for this tenant'**
  String get noReadingsRecordedForThisTenant;

  /// No description provided for @readingMonth.
  ///
  /// In en, this message translates to:
  /// **'Reading Month'**
  String get readingMonth;

  /// No description provided for @creationDate.
  ///
  /// In en, this message translates to:
  /// **'Creation Date'**
  String get creationDate;

  /// No description provided for @consumption.
  ///
  /// In en, this message translates to:
  /// **'Consumption'**
  String get consumption;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In en, this message translates to:
  /// **'Unpaid'**
  String get unpaid;

  /// No description provided for @on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get on;

  /// No description provided for @viewDetails.
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// No description provided for @markAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as unpaid'**
  String get markAsUnpaid;

  /// No description provided for @markAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Mark as paid'**
  String get markAsPaid;

  /// No description provided for @readingDetails.
  ///
  /// In en, this message translates to:
  /// **'Reading Details'**
  String get readingDetails;

  /// No description provided for @tenant.
  ///
  /// In en, this message translates to:
  /// **'Tenant'**
  String get tenant;

  /// No description provided for @oldIndex.
  ///
  /// In en, this message translates to:
  /// **'Old Index'**
  String get oldIndex;

  /// No description provided for @newIndex.
  ///
  /// In en, this message translates to:
  /// **'New Index'**
  String get newIndex;

  /// No description provided for @appliedRate.
  ///
  /// In en, this message translates to:
  /// **'Applied Rate'**
  String get appliedRate;

  /// No description provided for @comment.
  ///
  /// In en, this message translates to:
  /// **'Comment'**
  String get comment;

  /// No description provided for @paymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatus;

  /// No description provided for @paymentDate.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get paymentDate;

  /// No description provided for @newReading.
  ///
  /// In en, this message translates to:
  /// **'New Reading'**
  String get newReading;

  /// No description provided for @modifyReading.
  ///
  /// In en, this message translates to:
  /// **'Modify Reading'**
  String get modifyReading;

  /// No description provided for @locataireRequired.
  ///
  /// In en, this message translates to:
  /// **'Please create at least one tenant first'**
  String get locataireRequired;

  /// No description provided for @indexesRequired.
  ///
  /// In en, this message translates to:
  /// **'Indexes are required'**
  String get indexesRequired;

  /// No description provided for @indexesMustBeValidNumbers.
  ///
  /// In en, this message translates to:
  /// **'Indexes must be valid numbers'**
  String get indexesMustBeValidNumbers;

  /// No description provided for @newIndexGreaterThanOldIndex.
  ///
  /// In en, this message translates to:
  /// **'New index must be greater than old index'**
  String get newIndexGreaterThanOldIndex;

  /// Error message when reading already exists for a month
  ///
  /// In en, this message translates to:
  /// **'A reading already exists for this tenant for the month of {month}'**
  String readingAlreadyExists(String month);

  /// No description provided for @readingAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reading added successfully'**
  String get readingAddedSuccessfully;

  /// No description provided for @readingModifiedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reading modified successfully'**
  String get readingModifiedSuccessfully;

  /// No description provided for @errorSavingReading.
  ///
  /// In en, this message translates to:
  /// **'Error saving reading'**
  String get errorSavingReading;

  /// No description provided for @confirmDeleteReading.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reading?'**
  String get confirmDeleteReading;

  /// No description provided for @readingDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Reading deleted successfully'**
  String get readingDeletedSuccessfully;

  /// No description provided for @errorDeletingReading.
  ///
  /// In en, this message translates to:
  /// **'Error deleting reading'**
  String get errorDeletingReading;

  /// No description provided for @readingMarkedAsPaid.
  ///
  /// In en, this message translates to:
  /// **'Reading marked as paid'**
  String get readingMarkedAsPaid;

  /// No description provided for @readingMarkedAsUnpaid.
  ///
  /// In en, this message translates to:
  /// **'Reading marked as unpaid'**
  String get readingMarkedAsUnpaid;

  /// No description provided for @errorUpdatingPaymentStatus.
  ///
  /// In en, this message translates to:
  /// **'Error updating payment status'**
  String get errorUpdatingPaymentStatus;

  /// No description provided for @apparence.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get apparence;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @light.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// No description provided for @dark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// No description provided for @generalSettings.
  ///
  /// In en, this message translates to:
  /// **'General Settings'**
  String get generalSettings;

  /// No description provided for @baseRatePerUnit.
  ///
  /// In en, this message translates to:
  /// **'Base rate per unit'**
  String get baseRatePerUnit;

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @currencyHelperText.
  ///
  /// In en, this message translates to:
  /// **'Currency used for calculations (e.g. FCFA, EUR, USD)'**
  String get currencyHelperText;

  /// No description provided for @saveConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Save Configuration'**
  String get saveConfiguration;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @managePinCode.
  ///
  /// In en, this message translates to:
  /// **'Manage PIN Code'**
  String get managePinCode;

  /// No description provided for @informations.
  ///
  /// In en, this message translates to:
  /// **'Informations'**
  String get informations;

  /// No description provided for @currentRate.
  ///
  /// In en, this message translates to:
  /// **'Current rate'**
  String get currentRate;

  /// No description provided for @lastModification.
  ///
  /// In en, this message translates to:
  /// **'Last modification'**
  String get lastModification;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Rentilax Marker v1.0.0'**
  String get appVersion;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'Consumption reading management application'**
  String get appDescription;

  /// No description provided for @features.
  ///
  /// In en, this message translates to:
  /// **'Features:'**
  String get features;

  /// No description provided for @manageCitiesTenants.
  ///
  /// In en, this message translates to:
  /// **'• Manage cities and tenants'**
  String get manageCitiesTenants;

  /// No description provided for @automatedReadings.
  ///
  /// In en, this message translates to:
  /// **'• Automated consumption readings'**
  String get automatedReadings;

  /// No description provided for @automaticAmountCalculation.
  ///
  /// In en, this message translates to:
  /// **'• Automatic amount calculation'**
  String get automaticAmountCalculation;

  /// No description provided for @customizableRates.
  ///
  /// In en, this message translates to:
  /// **'• Customizable rates per tenant'**
  String get customizableRates;

  /// No description provided for @baseRateRequired.
  ///
  /// In en, this message translates to:
  /// **'Base rate is required'**
  String get baseRateRequired;

  /// No description provided for @positiveRate.
  ///
  /// In en, this message translates to:
  /// **'Rate must be a positive number'**
  String get positiveRate;

  /// No description provided for @configurationSavedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Configuration saved successfully'**
  String get configurationSavedSuccessfully;

  /// No description provided for @errorSavingConfiguration.
  ///
  /// In en, this message translates to:
  /// **'Error saving configuration'**
  String get errorSavingConfiguration;

  /// No description provided for @pinSettings.
  ///
  /// In en, this message translates to:
  /// **'PIN Settings'**
  String get pinSettings;

  /// No description provided for @setPinCode.
  ///
  /// In en, this message translates to:
  /// **'Set PIN Code'**
  String get setPinCode;

  /// No description provided for @currentPin.
  ///
  /// In en, this message translates to:
  /// **'Current PIN'**
  String get currentPin;

  /// No description provided for @newPin.
  ///
  /// In en, this message translates to:
  /// **'New PIN'**
  String get newPin;

  /// No description provided for @confirmNewPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm New PIN'**
  String get confirmNewPin;

  /// No description provided for @changePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get changePin;

  /// No description provided for @pinCodeSetSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN code set successfully'**
  String get pinCodeSetSuccessfully;

  /// No description provided for @pinCodeChangedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN code changed successfully'**
  String get pinCodeChangedSuccessfully;

  /// No description provided for @pinCodeRemovedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'PIN code removed successfully'**
  String get pinCodeRemovedSuccessfully;

  /// No description provided for @errorSettingPinCode.
  ///
  /// In en, this message translates to:
  /// **'Error setting PIN code'**
  String get errorSettingPinCode;

  /// No description provided for @errorChangingPinCode.
  ///
  /// In en, this message translates to:
  /// **'Error changing PIN code'**
  String get errorChangingPinCode;

  /// No description provided for @errorRemovingPinCode.
  ///
  /// In en, this message translates to:
  /// **'Error removing PIN code'**
  String get errorRemovingPinCode;

  /// No description provided for @pinCodeRequired.
  ///
  /// In en, this message translates to:
  /// **'PIN code is required'**
  String get pinCodeRequired;

  /// No description provided for @pinCodeMustBe5Digits.
  ///
  /// In en, this message translates to:
  /// **'PIN code must be 5 digits'**
  String get pinCodeMustBe5Digits;

  /// No description provided for @pinCodesDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'PIN codes do not match'**
  String get pinCodesDoNotMatch;

  /// No description provided for @incorrectCurrentPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current PIN'**
  String get incorrectCurrentPin;

  /// No description provided for @enterYourPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN to access the application'**
  String get enterYourPin;

  /// No description provided for @incorrectPin.
  ///
  /// In en, this message translates to:
  /// **'Incorrect PIN'**
  String get incorrectPin;

  /// No description provided for @pleaseEnter5DigitsPin.
  ///
  /// In en, this message translates to:
  /// **'Please enter a 5-digit PIN'**
  String get pleaseEnter5DigitsPin;

  /// No description provided for @unlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// No description provided for @searchTenant.
  ///
  /// In en, this message translates to:
  /// **'Search tenant...'**
  String get searchTenant;

  /// No description provided for @searchReading.
  ///
  /// In en, this message translates to:
  /// **'Search reading...'**
  String get searchReading;

  /// No description provided for @paymentStatusFilter.
  ///
  /// In en, this message translates to:
  /// **'Payment Status'**
  String get paymentStatusFilter;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @cityFilter.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityFilter;

  /// No description provided for @allCities.
  ///
  /// In en, this message translates to:
  /// **'All Cities'**
  String get allCities;

  /// No description provided for @monthFilter.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get monthFilter;

  /// No description provided for @allMonths.
  ///
  /// In en, this message translates to:
  /// **'All Months'**
  String get allMonths;

  /// No description provided for @noTenantFound.
  ///
  /// In en, this message translates to:
  /// **'No tenant found'**
  String get noTenantFound;

  /// No description provided for @noRelevesFound.
  ///
  /// In en, this message translates to:
  /// **'No readings found'**
  String get noRelevesFound;

  /// No description provided for @errorLoadingHistory.
  ///
  /// In en, this message translates to:
  /// **'Error loading history'**
  String get errorLoadingHistory;

  /// No description provided for @errorLoadingStats.
  ///
  /// In en, this message translates to:
  /// **'Error loading stats'**
  String get errorLoadingStats;

  /// No description provided for @errorLoading.
  ///
  /// In en, this message translates to:
  /// **'Error loading'**
  String get errorLoading;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Permission denied'**
  String get permissionDenied;

  /// No description provided for @noContactFound.
  ///
  /// In en, this message translates to:
  /// **'No contact found'**
  String get noContactFound;

  /// No description provided for @selectContact.
  ///
  /// In en, this message translates to:
  /// **'Select a contact'**
  String get selectContact;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No description provided for @totalPaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Paid Amount'**
  String get totalPaidAmount;

  /// No description provided for @totalUnpaidAmount.
  ///
  /// In en, this message translates to:
  /// **'Total Unpaid Amount'**
  String get totalUnpaidAmount;

  /// No description provided for @units.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get units;

  /// No description provided for @unit.
  ///
  /// In en, this message translates to:
  /// **'unit'**
  String get unit;

  /// No description provided for @optional.
  ///
  /// In en, this message translates to:
  /// **'optional'**
  String get optional;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @receiptOfConsumption.
  ///
  /// In en, this message translates to:
  /// **'Receipt of Consumption'**
  String get receiptOfConsumption;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @log.
  ///
  /// In en, this message translates to:
  /// **'Log'**
  String get log;

  /// No description provided for @month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get month;

  /// No description provided for @createdOn.
  ///
  /// In en, this message translates to:
  /// **'Created on'**
  String get createdOn;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @consumptionReport.
  ///
  /// In en, this message translates to:
  /// **'Consumption Report'**
  String get consumptionReport;

  /// Page number indicator
  ///
  /// In en, this message translates to:
  /// **'Page {number}'**
  String pageNumber(int number);

  /// Generation date indicator
  ///
  /// In en, this message translates to:
  /// **'Generated on {date}'**
  String generatedOn(String date);

  /// Total readings count
  ///
  /// In en, this message translates to:
  /// **'Total readings: {count}'**
  String totalReadings(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
