import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/settings_repository.dart';
import '../repositories/settings_repository_impl.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SettingsRepository>(
      () => SettingsRepositoryImpl(Supabase.instance.client),
    );
    Get.lazyPut<SettingsViewModel>(
      () => SettingsViewModel(Get.find<SettingsRepository>()),
    );
  }
}
