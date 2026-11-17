import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/business_report.dart';
import 'report_repository.dart';

class ReportRepositoryImpl implements ReportRepository {
  ReportRepositoryImpl(this._client);
  final SupabaseClient _client;

  @override
  Future<BusinessReport> load({
    required DateTime start,
    required DateTime end,
  }) async {
    if (start.isAfter(end)) {
      throw ArgumentError('Start date must be before end date.');
    }
    if (_client.auth.currentUser == null) {
      throw AuthException('Sign in to view reports.');
    }
    final first = DateTime(start.year, start.month, start.day);
    final exclusiveEnd = DateTime(end.year, end.month, end.day + 1);
    final result = await _client.rpc(
      'dk_financial_snapshot',
      params: {
        'p_start': first.toUtc().toIso8601String(),
        'p_end': exclusiveEnd.toUtc().toIso8601String(),
      },
    );
    final value = Map<String, dynamic>.from(result as Map);
    final daily = (value['daily'] as List<dynamic>).map((raw) {
      final row = Map<String, dynamic>.from(raw as Map);
      return DailyBusinessTotal(
        day: DateTime.parse(row['day'] as String),
        credit: (row['credit'] as num).toDouble(),
        payments: (row['payments'] as num).toDouble(),
      );
    }).toList();
    return BusinessReport(
      start: start,
      end: end,
      credit: (value['period_credit'] as num).toDouble(),
      payments: (value['period_payments'] as num).toDouble(),
      outstanding: (value['outstanding'] as num).toDouble(),
      customerCount: (value['customer_count'] as num).toInt(),
      productCount: (value['product_count'] as num).toInt(),
      inventoryCostValue: (value['inventory_cost_value'] as num).toDouble(),
      supplierCount: (value['supplier_count'] as num).toInt(),
      supplierPayable: (value['supplier_payable'] as num).toDouble(),
      daily: daily,
    );
  }
}
