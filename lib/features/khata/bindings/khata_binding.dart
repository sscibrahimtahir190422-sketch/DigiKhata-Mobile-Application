import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/repositories/customer_repositories_impl.dart';
import '../../customers/repositories/customer_repositories.dart';
import '../repositories/khata_repository.dart';
import '../repositories/khata_repository_impl.dart';
import '../viewmodels/khata_view_model.dart';

class KhataBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;

    if (arguments is! Map || arguments['customerId'] is! String) {
      throw ArgumentError('KhataBinding requires a customerId route argument.');
    }

    final customerId = arguments['customerId'] as String;
    final supabase = Supabase.instance.client;

    Get.lazyPut<CustomerRepository>(() => CustomerRepositoryImpl(supabase));

    Get.lazyPut<KhataRepository>(() => KhataRepositoryImpl(supabase));

    Get.lazyPut<KhataViewModel>(
      () => KhataViewModel(Get.find<KhataRepository>(), customerId),
    );
  }
}
