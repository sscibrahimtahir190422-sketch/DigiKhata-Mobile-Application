import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class AuthRepository {
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  });

  Future<AuthResponse> signUp({
    required String email,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();

  User? get currentUser;
}
