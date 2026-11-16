import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/dashboard/models/dashboard_summary.dart';
import '../../features/dashboard/repositories/dashboard_repository.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  @override
  Future<DashboardSummary> getSummary() async {
    // Fetch actual customer count. Supabase RLS applies to this query.
    final customerResponse = await _supabase
        .from('customers')
        .select('id')
        .count(CountOption.exact);

    final customerCount = customerResponse.count;

    // Fetch actual credit and payment transactions.
    final transactions = await _supabase
        .from('khata_transactions')
        .select('type, amount');

    double totalCredits = 0;
    double totalPayments = 0;

    for (final transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type'] as String;

      if (type == 'credit') {
        totalCredits += amount;
      } else if (type == 'payment') {
        totalPayments += amount;
      }
    }

    // Calculate today's local date boundaries.
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final startOfTomorrow = startOfToday.add(const Duration(days: 1));

    // Convert boundaries to UTC for timestamp comparisons.
    final startUtc = startOfToday.toUtc().toIso8601String();
    final tomorrowUtc = startOfTomorrow.toUtc().toIso8601String();

    final todaysTransactions = await _supabase
        .from('khata_transactions')
        .select('type, amount')
        .gte('created_at', startUtc)
        .lt('created_at', tomorrowUtc);

    double todaySales = 0;
    double todayPayments = 0;

    for (final transaction in todaysTransactions) {
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type'] as String;

      if (type == 'credit') {
        todaySales += amount;
      } else if (type == 'payment') {
        todayPayments += amount;
      }
    }

    return DashboardSummary(
      totalReceivables: totalCredits - totalPayments,
      todaySales: todaySales,
      todayPayments: todayPayments,
      customerCount: customerCount,
    );
  }
}
