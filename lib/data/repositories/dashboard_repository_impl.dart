import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/dashboard/models/dashboard_summary.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  DashboardRepositoryImpl(this._supabase);
  final SupabaseClient _supabase;

  @override
  Future<DashboardSummary> getSummary() async {
    if (_supabase.auth.currentUser == null) {
      throw const AuthException('Please sign in to view your dashboard.');
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final response = await _supabase.rpc(
      'dk_financial_snapshot',
      params: {
        'p_start': today.toUtc().toIso8601String(),
        'p_end': tomorrow.toUtc().toIso8601String(),
      },
    );
    final values = Map<String, dynamic>.from(response as Map);
    return DashboardSummary(
      totalReceivables: (values['outstanding'] as num).toDouble(),
      todaySales: (values['period_credit'] as num).toDouble(),
      todayPayments: (values['period_payments'] as num).toDouble(),
      customerCount: (values['customer_count'] as num).toInt(),
      supplierPayables: (values['supplier_payable'] as num).toDouble(),
      supplierCount: (values['supplier_count'] as num).toInt(),
      stockValue: (values['inventory_cost_value'] as num).toDouble(),
    );
  }
}
