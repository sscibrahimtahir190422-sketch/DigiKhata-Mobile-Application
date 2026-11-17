import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/inventory_repository.dart';
import '../repositories/inventory_repository_impl.dart';
import '../viewmodels/inventory_view_model.dart';

class InventoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<InventoryRepository>(
      () => InventoryRepositoryImpl(Supabase.instance.client),
    );
    Get.lazyPut<InventoryViewModel>(
      () => InventoryViewModel(Get.find<InventoryRepository>()),
    );
  }
}
