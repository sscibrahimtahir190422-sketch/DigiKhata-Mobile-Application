import 'package:get/get.dart';

import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends GetxController {
  DashboardViewModel(this._repository);

  final DashboardRepository _repository;

  final summary = DashboardSummary.empty().obs;
  final isLoading = false.obs;
  final errorMessage = RxnString();

  bool _hasLoadedSuccessfully = false;
  bool get hasLoadedSuccessfully => _hasLoadedSuccessfully;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (isLoading.value) return;

    if (!_hasLoadedSuccessfully) {
      isLoading.value = true;
    }

    errorMessage.value = null;

    try {
      final result = await _repository.getSummary();
      summary.value = result;
      _hasLoadedSuccessfully = true;
    } catch (_) {
      errorMessage.value = _hasLoadedSuccessfully
          ? 'Unable to refresh dashboard. Showing previous data.'
          : 'Unable to load dashboard. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }
}
