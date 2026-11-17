import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';

class AuthViewModel extends GetxController {
  AuthViewModel(this._authRepository);

  final AuthRepository _authRepository;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  Future<bool> signIn({required String email, required String password}) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = '';

    try {
      await _authRepository.signIn(email: email.trim(), password: password);

      return true;
    } on AuthException catch (e) {
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'Unexpected error: ${e.runtimeType}';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  final registrationEmailSent = false.obs;

  Future<bool> signUp({required String email, required String password}) async {
    if (isLoading.value) return false;
    isLoading.value = true;
    errorMessage.value = '';
    registrationEmailSent.value = false;
    try {
      final response = await _authRepository.signUp(
        email: email.trim(),
        password: password,
      );
      registrationEmailSent.value = response.session == null;
      return true;
    } on AuthException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value = 'Unable to create account. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> requestPasswordReset(String email) async {
    if (isLoading.value) return false;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      await _authRepository.sendPasswordReset(email.trim());
      return true;
    } on AuthException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value =
          'Unable to request password reset. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
  }
}
