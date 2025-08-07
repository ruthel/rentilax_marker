// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rentilax Marker';

  @override
  String get citesScreenTitle => 'Manage Cities';

  @override
  String get locatairesScreenTitle => 'Manage Tenants';

  @override
  String get relevesScreenTitle => 'Manage Readings';

  @override
  String get configurationScreenTitle => 'Configuration';

  @override
  String get noRelevesRecorded => 'No readings recorded';

  @override
  String get totalConsumption => 'Total Consumption';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get noReadingsForThisMonth => 'No readings for this month.';

  @override
  String get printMonthlyReport => 'Print Monthly Report';

  @override
  String get cities => 'Cities';

  @override
  String get tenants => 'Tenants';

  @override
  String get readings => 'Readings';

  @override
  String get configuration => 'Configuration';

  @override
  String get addCity => 'Add City';

  @override
  String get editCity => 'Edit City';

  @override
  String get cityName => 'City Name';

  @override
  String get address => 'Address';

  @override
  String get cancel => 'Cancel';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String get modify => 'Modify';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get cityAddedSuccessfully => 'City added successfully';

  @override
  String get cityModifiedSuccessfully => 'City modified successfully';

  @override
  String get errorSavingCity => 'Error saving city';

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String get cityDeletedSuccessfully => 'City deleted successfully';

  @override
  String get errorDeletingCity => 'Error deleting city';

  @override
  String get cityRequired => 'City name is required';

  @override
  String get noCitiesRecorded => 'No cities recorded';

  @override
  String confirmDeleteCity(String cityName) {
    return 'Are you sure you want to delete city \"$cityName\"?';
  }

  @override
  String get noTenantsRecorded => 'No tenants recorded';

  @override
  String get addTenant => 'Add Tenant';

  @override
  String get editTenant => 'Edit Tenant';

  @override
  String get chooseFromContacts => 'Choose from contacts';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get housingNumber => 'Housing Number';

  @override
  String get phone => 'Phone';

  @override
  String get email => 'Email';

  @override
  String get customRate => 'Custom Rate (FCFA)';

  @override
  String get leaveEmptyForBaseRate => 'Leave empty to use base rate';

  @override
  String get entryDate => 'Entry Date';

  @override
  String get tenantAddedSuccessfully => 'Tenant added successfully';

  @override
  String get tenantModifiedSuccessfully => 'Tenant modified successfully';

  @override
  String get errorSavingTenant => 'Error saving tenant';

  @override
  String get firstNameLastNameHousingRequired =>
      'First name, last name and housing number are required';

  @override
  String get invalidRate => 'Rate must be a valid number';

  @override
  String get tenantDeletedSuccessfully => 'Tenant deleted successfully';

  @override
  String get errorDeletingTenant => 'Error deleting tenant';

  @override
  String get noLocataireFound => 'No tenant found';

  @override
  String housingNumberExists(String housingNumber) {
    return 'Housing number \"$housingNumber\" already exists in this city';
  }

  @override
  String confirmDeleteTenant(String tenantName) {
    return 'Are you sure you want to delete tenant \"$tenantName\"?';
  }

  @override
  String get viewHistory => 'View History';

  @override
  String historyOf(String tenantName) {
    return 'History of $tenantName';
  }

  @override
  String get noReadingsRecordedForThisTenant =>
      'No readings recorded for this tenant';

  @override
  String get readingMonth => 'Reading Month';

  @override
  String get creationDate => 'Creation Date';

  @override
  String get consumption => 'Consumption';

  @override
  String get amount => 'Amount';

  @override
  String get status => 'Status';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get on => 'on';

  @override
  String get viewDetails => 'View Details';

  @override
  String get markAsUnpaid => 'Mark as unpaid';

  @override
  String get markAsPaid => 'Mark as paid';

  @override
  String get readingDetails => 'Reading Details';

  @override
  String get tenant => 'Tenant';

  @override
  String get oldIndex => 'Old Index';

  @override
  String get newIndex => 'New Index';

  @override
  String get appliedRate => 'Applied Rate';

  @override
  String get comment => 'Comment';

  @override
  String get paymentStatus => 'Payment Status';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get newReading => 'New Reading';

  @override
  String get modifyReading => 'Modify Reading';

  @override
  String get locataireRequired => 'Please create at least one tenant first';

  @override
  String get indexesRequired => 'Indexes are required';

  @override
  String get indexesMustBeValidNumbers => 'Indexes must be valid numbers';

  @override
  String get newIndexGreaterThanOldIndex =>
      'New index must be greater than old index';

  @override
  String readingAlreadyExists(String month) {
    return 'A reading already exists for this tenant for the month of $month';
  }

  @override
  String get readingAddedSuccessfully => 'Reading added successfully';

  @override
  String get readingModifiedSuccessfully => 'Reading modified successfully';

  @override
  String get errorSavingReading => 'Error saving reading';

  @override
  String get confirmDeleteReading =>
      'Are you sure you want to delete this reading?';

  @override
  String get readingDeletedSuccessfully => 'Reading deleted successfully';

  @override
  String get errorDeletingReading => 'Error deleting reading';

  @override
  String get readingMarkedAsPaid => 'Reading marked as paid';

  @override
  String get readingMarkedAsUnpaid => 'Reading marked as unpaid';

  @override
  String get errorUpdatingPaymentStatus => 'Error updating payment status';

  @override
  String get apparence => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get system => 'System';

  @override
  String get light => 'Light';

  @override
  String get dark => 'Dark';

  @override
  String get generalSettings => 'General Settings';

  @override
  String get baseRatePerUnit => 'Base rate per unit';

  @override
  String get currency => 'Currency';

  @override
  String get currencyHelperText =>
      'Currency used for calculations (e.g. FCFA, EUR, USD)';

  @override
  String get saveConfiguration => 'Save Configuration';

  @override
  String get security => 'Security';

  @override
  String get managePinCode => 'Manage PIN Code';

  @override
  String get informations => 'Informations';

  @override
  String get currentRate => 'Current rate';

  @override
  String get lastModification => 'Last modification';

  @override
  String get about => 'About';

  @override
  String get appVersion => 'Rentilax Marker v1.0.0';

  @override
  String get appDescription => 'Consumption reading management application';

  @override
  String get features => 'Features:';

  @override
  String get manageCitiesTenants => '• Manage cities and tenants';

  @override
  String get automatedReadings => '• Automated consumption readings';

  @override
  String get automaticAmountCalculation => '• Automatic amount calculation';

  @override
  String get customizableRates => '• Customizable rates per tenant';

  @override
  String get baseRateRequired => 'Base rate is required';

  @override
  String get positiveRate => 'Rate must be a positive number';

  @override
  String get configurationSavedSuccessfully =>
      'Configuration saved successfully';

  @override
  String get errorSavingConfiguration => 'Error saving configuration';

  @override
  String get pinSettings => 'PIN Settings';

  @override
  String get setPinCode => 'Set PIN Code';

  @override
  String get currentPin => 'Current PIN';

  @override
  String get newPin => 'New PIN';

  @override
  String get confirmNewPin => 'Confirm New PIN';

  @override
  String get changePin => 'Change PIN';

  @override
  String get pinCodeSetSuccessfully => 'PIN code set successfully';

  @override
  String get pinCodeChangedSuccessfully => 'PIN code changed successfully';

  @override
  String get pinCodeRemovedSuccessfully => 'PIN code removed successfully';

  @override
  String get errorSettingPinCode => 'Error setting PIN code';

  @override
  String get errorChangingPinCode => 'Error changing PIN code';

  @override
  String get errorRemovingPinCode => 'Error removing PIN code';

  @override
  String get pinCodeRequired => 'PIN code is required';

  @override
  String get pinCodeMustBe5Digits => 'PIN code must be 5 digits';

  @override
  String get pinCodesDoNotMatch => 'PIN codes do not match';

  @override
  String get incorrectCurrentPin => 'Incorrect current PIN';

  @override
  String get enterYourPin => 'Enter your PIN to access the application';

  @override
  String get incorrectPin => 'Incorrect PIN';

  @override
  String get pleaseEnter5DigitsPin => 'Please enter a 5-digit PIN';

  @override
  String get unlock => 'Unlock';

  @override
  String get searchTenant => 'Search tenant...';

  @override
  String get searchReading => 'Search reading...';

  @override
  String get paymentStatusFilter => 'Payment Status';

  @override
  String get all => 'All';

  @override
  String get cityFilter => 'City';

  @override
  String get allCities => 'All Cities';

  @override
  String get monthFilter => 'Month';

  @override
  String get allMonths => 'All Months';

  @override
  String get noTenantFound => 'No tenant found';

  @override
  String get noRelevesFound => 'No readings found';

  @override
  String get errorLoadingHistory => 'Error loading history';

  @override
  String get errorLoadingStats => 'Error loading stats';

  @override
  String get errorLoading => 'Error loading';

  @override
  String get permissionDenied => 'Permission denied';

  @override
  String get noContactFound => 'No contact found';

  @override
  String get selectContact => 'Select a contact';

  @override
  String get search => 'Search...';

  @override
  String get totalPaidAmount => 'Total Paid Amount';

  @override
  String get totalUnpaidAmount => 'Total Unpaid Amount';

  @override
  String get units => 'units';

  @override
  String get unit => 'unit';

  @override
  String get optional => 'optional';

  @override
  String get unknown => 'Unknown';

  @override
  String get receiptOfConsumption => 'Receipt of Consumption';

  @override
  String get city => 'City';

  @override
  String get log => 'Log';

  @override
  String get month => 'Month';

  @override
  String get createdOn => 'Created on';

  @override
  String get note => 'Note';

  @override
  String get consumptionReport => 'Consumption Report';

  @override
  String pageNumber(int number) {
    return 'Page $number';
  }

  @override
  String generatedOn(String date) {
    return 'Generated on $date';
  }

  @override
  String totalReadings(int count) {
    return 'Total readings: $count';
  }
}
