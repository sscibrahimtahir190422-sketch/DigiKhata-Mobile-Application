class DailyBusinessTotal {
  const DailyBusinessTotal({
    required this.day,
    required this.credit,
    required this.payments,
  });
  final DateTime day;
  final double credit;
  final double payments;
}

class BusinessReport {
  const BusinessReport({
    required this.start,
    required this.end,
    required this.credit,
    required this.payments,
    required this.outstanding,
    required this.customerCount,
    required this.productCount,
    required this.inventoryCostValue,
    this.supplierCount = 0,
    this.supplierPayable = 0,
    required this.daily,
  });
  final DateTime start;
  final DateTime end;
  final double credit;
  final double payments;
  final double outstanding;
  final int customerCount;
  final int productCount;
  final double inventoryCostValue;
  final int supplierCount;
  final double supplierPayable;
  final List<DailyBusinessTotal> daily;
  double get netActivity => credit - payments;
}
