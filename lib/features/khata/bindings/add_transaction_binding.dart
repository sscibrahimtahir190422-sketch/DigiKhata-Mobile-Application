import 'package:get/get.dart';

import '../viewmodels/khata_view_model.dart';

class AddTransactionBinding extends Bindings {
  @override
  void dependencies() {
    final arguments = Get.arguments;

    if (arguments is! Map || arguments['customerId'] is! String) {
      throw ArgumentError(
        'AddTransactionBinding requires a customerId route argument.',
      );
    }

    final customerId = arguments['customerId'] as String;

    if (!Get.isRegistered<KhataViewModel>()) {
      throw StateError(
        'KhataViewModel is not registered. Open the customer Khata screen first.',
      );
    }

    final controller = Get.find<KhataViewModel>();

    if (controller.customerId != customerId) {
      throw StateError(
        'The registered KhataViewModel belongs to a different customer.',
      );
    }
  }
}
