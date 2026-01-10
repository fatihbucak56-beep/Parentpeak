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

  Map<String, String> _stringsForLocale() => _localizedValues[locale.languageCode] ?? _localizedValues['en']!;

  String get appTitle => _stringsForLocale()['appTitle'] ?? 'Parentpeak';
  String get trustedDevicesTitle => _stringsForLocale()['trustedDevicesTitle'] ?? 'Trusted Devices';
  String get removeDeviceDialogTitle => _stringsForLocale()['removeDeviceDialogTitle'] ?? 'Remove device and delete data?';
  String removeDeviceDialogMessage(String deviceName) => (_stringsForLocale()['removeDeviceDialogMessage'] ?? 'Remove {deviceName}?').replaceAll('{deviceName}', deviceName);
  String get deviceNameLabel => _stringsForLocale()['deviceNameLabel'] ?? 'Enter device name';
  String get deviceNameHelper => _stringsForLocale()['deviceNameHelper'] ?? 'Enter the exact device name';
  String get cancel => _stringsForLocale()['cancel'] ?? 'Cancel';
  String get removeDevice => _stringsForLocale()['removeDevice'] ?? 'Remove device';
  String get deviceRemoved => _stringsForLocale()['deviceRemoved'] ?? 'Device removed successfully.';
  String get deviceRemoveError => _stringsForLocale()['deviceRemoveError'] ?? 'Failed to remove device.';
  String get cannotRemovePriority => _stringsForLocale()['cannotRemovePriority'] ?? 'This device cannot be removed.';
  String removedAt(String date) => (_stringsForLocale()['removedAt'] ?? 'Removed at: {date}').replaceAll('{date}', date);

  // New MVP strings
  String get chatTitle => _stringsForLocale()['chatTitle'] ?? 'Chat';
  String get chatLabel => _stringsForLocale()['chatLabel'] ?? 'Chat';
  String get calendarTitle => _stringsForLocale()['calendarTitle'] ?? 'Calendar';
  String get calendarLabel => _stringsForLocale()['calendarLabel'] ?? 'Calendar';
  String get devicesLabel => _stringsForLocale()['devicesLabel'] ?? 'Devices';
  String get messageHint => _stringsForLocale()['messageHint'] ?? 'Write a supportive message…';
  String get send => _stringsForLocale()['send'] ?? 'Send';
  String get noMessages => _stringsForLocale()['noMessages'] ?? 'No messages yet';
  String get addEvent => _stringsForLocale()['addEvent'] ?? 'Add event';
  String get noEvents => _stringsForLocale()['noEvents'] ?? 'No events yet';
  
  // FamilyWall inspired features
  String get locationTitle => _stringsForLocale()['locationTitle'] ?? 'Location';
  String get locationLabel => _stringsForLocale()['locationLabel'] ?? 'Location';
  String get todoTitle => _stringsForLocale()['todoTitle'] ?? 'To-Do';
  String get todoLabel => _stringsForLocale()['todoLabel'] ?? 'To-Do';
  String get shoppingTitle => _stringsForLocale()['shoppingTitle'] ?? 'Shopping';
  String get shoppingLabel => _stringsForLocale()['shoppingLabel'] ?? 'Shopping';
  String get photosTitle => _stringsForLocale()['photosTitle'] ?? 'Photos';
  String get photosLabel => _stringsForLocale()['photosLabel'] ?? 'Photos';
  String get contactsTitle => _stringsForLocale()['contactsTitle'] ?? 'Contacts';
  String get contactsLabel => _stringsForLocale()['contactsLabel'] ?? 'Contacts';
  String get moreLabel => _stringsForLocale()['moreLabel'] ?? 'More';

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
      'chatTitle': 'Pedagogy Chat',
      'chatLabel': 'Chat',
      'calendarTitle': 'Family Calendar',
      'calendarLabel': 'Calendar',
      'devicesLabel': 'Devices',
      'messageHint': 'Write a supportive message…',
      'send': 'Send',
      'noMessages': 'No messages yet',
      'addEvent': 'Add event',
      'noEvents': 'No events yet',
      'locationTitle': 'Family Location',
      'locationLabel': 'Location',
      'todoTitle': 'To-Do List',
      'todoLabel': 'To-Do',
      'shoppingTitle': 'Shopping List',
      'shoppingLabel': 'Shopping',
      'photosTitle': 'Family Photos',
      'photosLabel': 'Photos',
      'contactsTitle': 'Emergency Contacts',
      'contactsLabel': 'Contacts',
      'moreLabel': 'More',
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
      'chatTitle': 'Pädagogik-Chat',
      'chatLabel': 'Chat',
      'calendarTitle': 'Familienkalender',
      'calendarLabel': 'Kalender',
      'devicesLabel': 'Geräte',
      'messageHint': 'Schreibe eine unterstützende Nachricht…',
      'send': 'Senden',
      'noMessages': 'Noch keine Nachrichten',
      'addEvent': 'Termin hinzufügen',
      'noEvents': 'Noch keine Termine',
      'locationTitle': 'Familien-Standorte',
      'locationLabel': 'Standort',
      'todoTitle': 'Aufgabenliste',
      'todoLabel': 'To-Do',
      'shoppingTitle': 'Einkaufsliste',
      'shoppingLabel': 'Einkauf',
      'photosTitle': 'Familienfotos',
      'photosLabel': 'Fotos',
      'contactsTitle': 'Notfallkontakte',
      'contactsLabel': 'Kontakte',
      'moreLabel': 'Mehr',
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
