import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalePreferences {
  LocalePreferences._();

  static Locale initialLocale(SupabaseClient client) =>
      client.auth.currentUser?.userMetadata?['language'] == 'ur'
      ? const Locale('ur', 'PK')
      : const Locale('en', 'US');

  /// Saves the preferred language on the signed-in user's Supabase account.
  static Future<void> change(SupabaseClient client, String language) async {
    if (language != 'ur' && language != 'en') {
      throw ArgumentError('Unsupported language.');
    }
    await client.auth.updateUser(UserAttributes(data: {'language': language}));
    Get.updateLocale(
      language == 'ur' ? const Locale('ur', 'PK') : const Locale('en', 'US'),
    );
  }
}
