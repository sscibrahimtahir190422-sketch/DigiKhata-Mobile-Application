import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../khata/repositories/khata_repository.dart';
import '../../khata/repositories/khata_repository_impl.dart';
import '../repositories/customer_statement_repository.dart';
import '../viewmodels/customer_statement_view_model.dart';
import '../../customers/models/customer.dart';

class CustomerStatementBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;

    if (arguments is! Map || arguments['customer'] is! Customer) {
      throw ArgumentError(
        'CustomerStatementBinding requires a customer route argument.',
      );
    }

    final customer = arguments['customer'] as Customer;
    final supabase = Supabase.instance.client;

    Get.lazyPut<KhataRepository>(() => KhataRepositoryImpl(supabase));

    Get.lazyPut<CustomerStatementRepository>(
      () => CustomerStatementRepository(
        khataRepository: Get.find<KhataRepository>(),
      ),
    );

    Get.lazyPut<CustomerStatementViewModel>(
      () => CustomerStatementViewModel(
        statementRepository: Get.find<CustomerStatementRepository>(),
        customer: customer,
      ),
    );
  }
}
