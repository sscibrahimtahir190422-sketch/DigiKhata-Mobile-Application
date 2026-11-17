import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/supplier_repository.dart';
import '../repositories/supplier_repository_impl.dart';
import '../viewmodels/supplier_view_model.dart';

class SupplierBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SupplierRepository>(
      () => SupplierRepositoryImpl(Supabase.instance.client),
    );
    Get.lazyPut<SupplierViewModel>(() => SupplierViewModel(Get.find()));
  }
}
