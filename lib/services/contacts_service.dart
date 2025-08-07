import 'package:flutter_contacts/flutter_contacts.dart';

class ContactsHelper {
  /// Demande la permission d'accéder aux contacts
  static Future<bool> requestContactsPermission() async {
    try {
      return await FlutterContacts.requestPermission();
    } catch (e) {
      return false;
    }
  }

  /// Récupère la liste des contacts
  static Future<List<Contact>> getContacts() async {
    try {
      return await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );
    } catch (e) {
      return [];
    }
  }

  /// Parse le nom d'affichage en prénom et nom
  static List<String> parseDisplayName(String displayName) {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      final firstName = parts.first;
      final lastName = parts.skip(1).join(' ');
      return [firstName, lastName];
    } else if (parts.length == 1) {
      return [parts.first, ''];
    } else {
      return ['', ''];
    }
  }

  /// Récupère le numéro de téléphone principal du contact
  static String getContactPhone(Contact contact) {
    if (contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }
    return '';
  }

  /// Récupère l'email principal du contact
  static String getContactEmail(Contact contact) {
    if (contact.emails.isNotEmpty) {
      return contact.emails.first.address;
    }
    return '';
  }
}
