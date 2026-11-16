import 'package:digikhata/features/statements/models/statement_entry.dart';

class CustomerStatement {
  const CustomerStatement({
    required this.customerId,
    required this.customerName,
    required this.startDate,
    required this.endDate,
    required this.openingBalance,
    required this.totalCredit,
    required this.totalPayments,
    required this.entries,
  });

  final String customerId;
  final String customerName;
  final DateTime startDate;
  final DateTime endDate;
  final double openingBalance;
  final double totalCredit;
  final double totalPayments;
  final List<StatementEntry> entries;

  double get closingBalance => openingBalance + totalCredit - totalPayments;
}
