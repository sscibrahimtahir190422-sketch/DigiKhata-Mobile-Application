class DashboardSummary {
  const DashboardSummary({
    required this.totalReceivables,
    required this.todaySales,
    required this.todayPayments,
    required this.customerCount,
  });

  final double totalReceivables;
  final double todaySales;
  final double todayPayments;
  final int customerCount;

  factory DashboardSummary.empty() {
    return const DashboardSummary(
      totalReceivables: 0,
      todaySales: 0,
      todayPayments: 0,
      customerCount: 0,
    );
  }
}
