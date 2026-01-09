import 'package:flutter/widgets.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static const localizationsDelegates = [delegate];
  static const supportedLocales = [Locale('en'), Locale('de')];

  String get appTitle => _localizedValues[locale.languageCode]!['appTitle']!;
  String get trustedDevicesTitle => _localizedValues[locale.languageCode]!['trustedDevicesTitle']!;
  String get removeDeviceDialogTitle => _localizedValues[locale.languageCode]!['removeDeviceDialogTitle']!;
  String removeDeviceDialogMessage(String deviceName) => _localizedValues[locale.languageCode]!['removeDeviceDialogMessage']!.replaceAll('{deviceName}', deviceName);
  String get deviceNameLabel => _localizedValues[locale.languageCode]!['deviceNameLabel']!;
  String get deviceNameHelper => _localizedValues[locale.languageCode]!['deviceNameHelper']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get removeDevice => _localizedValues[locale.languageCode]!['removeDevice']!;
  String get deviceRemoved => _localizedValues[locale.languageCode]!['deviceRemoved']!;
  String get deviceRemoveError => _localizedValues[locale.languageCode]!['deviceRemoveError']!;
  String get cannotRemovePriority => _localizedValues[locale.languageCode]!['cannotRemovePriority']!;
  String removedAt(String date) => _localizedValues[locale.languageCode]!['removedAt']!.replaceAll('{date}', date);

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'Parentpeak',
      'trustedDevicesTitle': 'Trusted Devices',
      'removeDeviceDialogTitle': 'Remove device and delete data?',
      'removeDeviceDialogMessage': 'You are about to remove "{deviceName}" from your Trusted Circle. This will delete local data and keys on the target device permanently. Please type the device name to confirm:',
      'deviceNameLabel': 'Enter device name',
      'deviceNameHelper': 'Enter the exact device name',
      'cancel': 'Cancel',
      'removeDevice': 'Remove device',
      'deviceRemoved': 'Device removed successfully.',
      'deviceRemoveError': 'Failed to remove device.',
      'cannotRemovePriority': 'This device cannot be removed.',
      'removedAt': 'Removed at: {date}',
    },
    'de': {
      'appTitle': 'Parentpeak',
      'trustedDevicesTitle': 'Vertrauenswürdige Geräte',
      'removeDeviceDialogTitle': 'Gerät entfernen und Daten löschen?',
      'removeDeviceDialogMessage': 'Sie entfernen das Gerät "{deviceName}" aus Ihrem Trusted Circle. Dies löscht alle lokal gespeicherten Daten und Schlüssel auf dem Zielgerät unwiderruflich. Bitte geben Sie den Gerätenamen zur Bestätigung ein:',
      'deviceNameLabel': 'Gerätename eingeben',
      'deviceNameHelper': 'Geben Sie den Gerätenamen exakt ein',
      'cancel': 'Abbrechen',
      'removeDevice': 'Gerät entfernen',
      'deviceRemoved': 'Gerät erfolgreich entfernt.',
      'deviceRemoveError': 'Fehler beim Entfernen des Geräts.',
      'cannotRemovePriority': 'Dieses Gerät kann nicht entfernt werden.',
      'removedAt': 'Entfernt am: {date}',
    }
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;
}
