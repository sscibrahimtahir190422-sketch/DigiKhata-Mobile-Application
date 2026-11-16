import 'package:get/get.dart';

import '../../../data/repositories/dashboard_repository_impl.dart';
import '../viewmodels/dashboard_view_model.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DashboardRepositoryImpl>(() => DashboardRepositoryImpl());

    Get.lazyPut<DashboardViewModel>(
      () => DashboardViewModel(Get.find<DashboardRepositoryImpl>()),
    );
  }
}
