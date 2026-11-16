import 'package:get/get.dart';

import '../../../features/customers/models/customer.dart';
import '../models/customer_statement.dart';
import '../repositories/customer_statement_repository.dart';

class CustomerStatementViewModel extends GetxController {
  CustomerStatementViewModel({
    required this._statementRepository,
    required this.customer,
  });

  final CustomerStatementRepository _statementRepository;
  final Customer customer;

  final Rxn<CustomerStatement> statement = Rxn<CustomerStatement>();
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  final Rx<DateTime> startDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    1,
  ).obs;

  final Rx<DateTime> endDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadStatement();
  }

  Future<void> loadStatement() async {
    if (isLoading.value) return;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      statement.value = await _statementRepository.getStatement(
        customer: customer,
        startDate: startDate.value,
        endDate: endDate.value,
      );
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateDateRange({
    required DateTime start,
    required DateTime end,
  }) async {
    if (end.isBefore(start)) {
      errorMessage.value = 'End date cannot be before start date.';
      return;
    }

    startDate.value = start;
    endDate.value = end;
    await loadStatement();
  }
}
