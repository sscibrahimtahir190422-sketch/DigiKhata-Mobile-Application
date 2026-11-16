import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/customer_repositories_impl.dart';
import '../viewmodels/customer_view_model.dart';

class CustomerBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CustomerRepositoryImpl>()) {
      Get.put<CustomerRepositoryImpl>(
        CustomerRepositoryImpl(Supabase.instance.client),
        permanent: true,
      );
    }

    Get.lazyPut<CustomerViewModel>(
      () => CustomerViewModel(Get.find<CustomerRepositoryImpl>()),
    );
  }
}
