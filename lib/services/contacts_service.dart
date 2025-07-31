import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

class ContactsHelper {
  static Future<bool> requestContactsPermission() async {
    final permission = await Permission.contacts.request();
    return permission == PermissionStatus.granted;
  }

  static Future<List<Contact>> getContacts() async {
    try {
      final hasPermission = await requestContactsPermission();
      if (!hasPermission) {
        return [];
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);

      // Filtrer les contacts qui ont au moins un nom
      return contacts.where((contact) => 
        contact.displayName.trim().isNotEmpty
      ).toList();
    } catch (e) {
      print('Erreur lors de la récupération des contacts: $e');
      return [];
    }
  }

  static String getContactPhone(Contact contact) {
    if (contact.phones.isNotEmpty) {
      return contact.phones.first.number;
    }
    return '';
  }

  static String getContactEmail(Contact contact) {
    if (contact.emails.isNotEmpty) {
      return contact.emails.first.address;
    }
    return '';
  }

  static List<String> parseDisplayName(String displayName) {
    final parts = displayName.trim().split(' ');
    if (parts.length >= 2) {
      final prenom = parts.first;
      final nom = parts.skip(1).join(' ');
      return [prenom, nom];
    } else if (parts.length == 1) {
      return [parts.first, ''];
    }
    return ['', ''];
  }
}
