import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/dashboard_repository_impl.dart';
import '../viewmodels/dashboard_view_model.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardRepositoryImpl>(
      () => DashboardRepositoryImpl(Supabase.instance.client),
    );

    Get.lazyPut<DashboardViewModel>(
      () => DashboardViewModel(Get.find<DashboardRepositoryImpl>()),
    );
  }
}
