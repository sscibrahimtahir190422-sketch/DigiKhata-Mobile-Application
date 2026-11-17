import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/report_repository.dart';
import '../repositories/report_repository_impl.dart';
import '../viewmodels/report_view_model.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReportRepository>(
      () => ReportRepositoryImpl(Supabase.instance.client),
    );
    Get.lazyPut<ReportViewModel>(
      () => ReportViewModel(Get.find<ReportRepository>()),
    );
  }
}
