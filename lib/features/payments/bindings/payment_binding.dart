import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/payment_repository.dart';
import '../repositories/payment_repository_impl.dart';
import '../viewmodels/payment_view_model.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PaymentRepository>(
      () => PaymentRepositoryImpl(Supabase.instance.client),
    );
    Get.lazyPut<PaymentViewModel>(
      () => PaymentViewModel(Get.find<PaymentRepository>()),
    );
  }
}
