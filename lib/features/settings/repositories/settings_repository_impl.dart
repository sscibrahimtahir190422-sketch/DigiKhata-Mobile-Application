import 'package:supabase_flutter/supabase_flutter.dart';
import 'settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(this._client);
  final SupabaseClient _client;
  @override
  String? get currentEmail => _client.auth.currentUser?.email;
  @override
  Future<void> signOut() => _client.auth.signOut();
}
