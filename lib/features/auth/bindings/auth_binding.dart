import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/auth_repository_impl.dart';
import '../repositories/auth_repository.dart';
import '../viewmodels/auth_view_model.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(
      () => AuthRepositoryImpl(Supabase.instance.client),
    );

    Get.lazyPut<AuthViewModel>(() => AuthViewModel(Get.find<AuthRepository>()));
  }
}
