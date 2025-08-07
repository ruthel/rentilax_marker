import 'package:flutter/material.dart';
import 'generated/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    if (localizations == null) {
      throw Exception(
          'AppLocalizations not found. Make sure to add AppLocalizations.delegate to your MaterialApp.');
    }
    return localizations;
  }
}
