abstract interface class SettingsRepository {
  String? get currentEmail;
  Future<void> signOut();
}
