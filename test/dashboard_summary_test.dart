import 'package:flutter_test/flutter_test.dart';
import 'package:digikhata/features/dashboard/models/dashboard_summary.dart';

void main() {
  test('Empty dashboard never uses random or mock amounts', () {
    final model = DashboardSummary.empty();
    expect(model.totalReceivables, 0);
    expect(model.todaySales, 0);
    expect(model.todayPayments, 0);
    expect(model.customerCount, 0);
    expect(model.supplierPayables, 0);
    expect(model.stockValue, 0);
  });
}
