class DashboardSummary {
  const DashboardSummary({
    required this.totalReceivables,
    required this.todaySales,
    required this.todayPayments,
    required this.customerCount,
    this.supplierPayables = 0,
    this.supplierCount = 0,
    this.stockValue = 0,
  });

  final double totalReceivables;
  final double todaySales;
  final double todayPayments;
  final int customerCount;
  final double supplierPayables;
  final int supplierCount;
  final double stockValue;

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      totalReceivables: 0,
      todaySales: 0,
      todayPayments: 0,
      customerCount: 0,
    );
  }
}
