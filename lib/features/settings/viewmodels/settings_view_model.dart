import 'package:get/get.dart';
import '../../../app/routes/app_routes.dart';
import '../repositories/settings_repository.dart';

class SettingsViewModel extends GetxController {
  SettingsViewModel(this._repository);
  final SettingsRepository _repository;
  final busy = false.obs;
  final error = RxnString();
  String get currentEmail => _repository.currentEmail ?? 'Signed in';
  Future<void> signOut() async {
    if (busy.value) return;
    busy.value = true;
    error.value = null;
    try {
      await _repository.signOut();
      Get.offAllNamed(AppRoutes.login);
    } catch (e) {
      error.value = 'Unable to sign out: $e';
    } finally {
      busy.value = false;
    }
  }
}
