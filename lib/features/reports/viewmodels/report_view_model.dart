import '../../../core/services/realtime_watch.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get/get.dart';
import '../models/business_report.dart';
import '../repositories/report_repository.dart';

class ReportViewModel extends GetxController {
  RealtimeWatch? _realtime;

  ReportViewModel(this._repository);
  final ReportRepository _repository;
  final report = Rxn<BusinessReport>();
  final loading = false.obs;
  final error = RxnString();
  final start = DateTime(DateTime.now().year, DateTime.now().month, 1).obs;
  final end = DateTime.now().obs;
  @override
  void onInit() {
    super.onInit();
    _realtime = RealtimeWatch(Supabase.instance.client);
    _realtime!.watch(table: 'khata_transactions', onChange: () => load());
    _realtime!.watch(table: 'customers', onChange: () => load());
    _realtime!.watch(table: 'products', onChange: () => load());
    _realtime!.watch(table: 'supplier_transactions', onChange: () => load());
    load();
  }

  Future<void> setRange(DateTime first, DateTime last) async {
    start.value = first;
    end.value = last;
    await load();
  }

  Future<void> load() async {
    if (loading.value) return;
    loading.value = true;
    error.value = null;
    try {
      report.value = await _repository.load(start: start.value, end: end.value);
    } catch (e) {
      error.value = 'Unable to load report: $e';
    } finally {
      loading.value = false;
    }
  }

  @override
  void onClose() {
    _realtime?.dispose();
    super.onClose();
  }
}
