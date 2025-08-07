import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_en.dart';

abstract class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
  ];

  String get appTitle;
  String get citesScreenTitle;
  String get locatairesScreenTitle;
  String get relevesScreenTitle;
  String get configurationScreenTitle;
  String get noRelevesRecorded;
  String get totalConsumption;
  String get totalAmount;
  String get noReadingsForThisMonth;
  String get printMonthlyReport;
  String get cities;
  String get tenants;
  String get readings;
  String get configuration;
  String get addCity;
  String get editCity;
  String get cityName;
  String get address;
  String get cancel;
  String get add;
  String get save;
  String get cityAddedSuccessfully;
  String get cityModifiedSuccessfully;
  String get errorSavingCity;
  String get confirmDeletion;
  String confirmDeleteCity(Object cityName);
  String get delete;
  String get cityDeletedSuccessfully;
  String get errorDeletingCity;
  String get cityRequired;
  String get noTenantsRecorded;
  String get addTenant;
  String get editTenant;
  String get chooseFromContacts;
  String get firstName;
  String get lastName;
  String get housingNumber;
  String get phone;
  String get email;
  String get customRate;
  String get leaveEmptyForBaseRate;
  String get entryDate;
  String get tenantAddedSuccessfully;
  String get tenantModifiedSuccessfully;
  String get errorSavingTenant;
  String get firstNameLastNameHousingRequired;
  String get invalidRate;
  String housingNumberExists(Object housingNumber);
  String confirmDeleteTenant(Object tenantName);
  String get tenantDeletedSuccessfully;
  String get errorDeletingTenant;
  String get noLocataireFound;
  String get viewHistory;
  String historyOf(Object tenantName);
  String get noReadingsRecordedForThisTenant;
  String get readingMonth;
  String get creationDate;
  String get consumption;
  String get amount;
  String get status;
  String get paid;
  String get unpaid;
  String get on;
  String get viewDetails;
  String get modify;
  String get markAsUnpaid;
  String get markAsPaid;
  String get readingDetails;
  String get tenant;
  String get oldIndex;
  String get newIndex;
  String get appliedRate;
  String get comment;
  String get paymentStatus;
  String get paymentDate;
  String get close;
  String get newReading;
  String get modifyReading;
  String get locataireRequired;
  String get indexesRequired;
  String get indexesMustBeValidNumbers;
  String get newIndexGreaterThanOldIndex;
  String readingAlreadyExists(Object month);
  String get readingAddedSuccessfully;
  String get readingModifiedSuccessfully;
  String get errorSavingReading;
  String get confirmDeleteReading;
  String get readingDeletedSuccessfully;
  String get errorDeletingReading;
  String get readingMarkedAsPaid;
  String get readingMarkedAsUnpaid;
  String get errorUpdatingPaymentStatus;
  String get apparence;
  String get theme;
  String get system;
  String get light;
  String get dark;
  String get generalSettings;
  String get baseRatePerUnit;
  String get currency;
  String get currencyHelperText;
  String get saveConfiguration;
  String get security;
  String get managePinCode;
  String get informations;
  String get currentRate;
  String get lastModification;
  String get about;
  String get appVersion;
  String get appDescription;
  String get features;
  String get manageCitiesTenants;
  String get automatedReadings;
  String get automaticAmountCalculation;
  String get customizableRates;
  String get baseRateRequired;
  String get positiveRate;
  String get configurationSavedSuccessfully;
  String get errorSavingConfiguration;
  String get pinSettings;
  String get currentPin;
  String get newPin;
  String get confirmNewPin;
  String get changePin;
  String get pinCodeSetSuccessfully;
  String get pinCodeChangedSuccessfully;
  String get pinCodeRemovedSuccessfully;
  String get errorSettingPinCode;
  String get errorChangingPinCode;
  String get errorRemovingPinCode;
  String get pinCodeRequired;
  String get pinCodeMustBe5Digits;
  String get pinCodesDoNotMatch;
  String get incorrectCurrentPin;
  String get enterYourPin;
  String get incorrectPin;
  String get pleaseEnter5DigitsPin;
  String get unlock;
  String get searchTenant;
  String get paymentStatusFilter;
  String get all;
  String get cityFilter;
  String get allCities;
  String get monthFilter;
  String get allMonths;
  String get noTenantFound;
  String get errorLoadingHistory;
  String get errorLoadingStats;
  String get errorLoading;
  String get permissionDenied;
  String get noContactFound;
  String get selectContact;
  String get search;
  String get totalPaidAmount;
  String get totalUnpaidAmount;
  String get units;
  String get unit;
  String get optional;
  String get searchReading;
  String get noRelevesFound;
  String get noCitiesRecorded;
  String get setPinCode;
  String get unknown;
  String get receiptOfConsumption;
  String get city;
  String get log;
  String get month;
  String get createdOn;
  String get note;
  String get consumptionReport;
  String pageNumber(Object number);
  String generatedOn(Object date);
  String totalReadings(Object count);
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn('en');
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue on GitHub with a '
      'reproducible sample app and the gen-l10n configuration that was used.');
}
