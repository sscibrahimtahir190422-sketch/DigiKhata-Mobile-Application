import '../../../core/services/realtime_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';

import '../models/dashboard_summary.dart';
import '../repositories/dashboard_repository.dart';

class DashboardViewModel extends GetxController {
  RealtimeWatch? _realtime;

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
    _realtime = RealtimeWatch(Supabase.instance.client);
    _realtime!.watch(table: 'customers', onChange: () => loadDashboard());
    _realtime!.watch(
      table: 'khata_transactions',
      onChange: () => loadDashboard(),
    );
    _realtime!.watch(table: 'products', onChange: () => loadDashboard());
    _realtime!.watch(table: 'suppliers', onChange: () => loadDashboard());
    _realtime!.watch(
      table: 'supplier_transactions',
      onChange: () => loadDashboard(),
    );

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

  @override
  void onClose() {
    _realtime?.dispose();
    super.onClose();
  }
}
