import '../../../features/customers/models/customer.dart';
import '../../khata/repositories/khata_repository.dart';
import '../models/customer_statement.dart';
import '../models/statement_entry.dart';

class CustomerStatementRepository {
  CustomerStatementRepository({required this._khataRepository});

  final KhataRepository _khataRepository;

  Future<CustomerStatement> getStatement({
    required Customer customer,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (endDate.isBefore(startDate)) {
      throw ArgumentError('End date must not be before start date.');
    }

    final transactions = await _khataRepository.getTransactions(
      customerId: customer.id,
    );

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final endExclusive = DateTime(endDate.year, endDate.month, endDate.day + 1);

    final ordered = transactions.toList()
      ..sort((a, b) {
        final result = a.createdAt.compareTo(b.createdAt);
        return result != 0 ? result : a.id.compareTo(b.id);
      });

    var openingBalance = 0.0;
    var totalCredit = 0.0;
    var totalPayments = 0.0;
    final entries = <StatementEntry>[];

    for (final transaction in ordered) {
      final date = transaction.createdAt.toLocal();

      if (date.isBefore(start)) {
        if (transaction.isCredit) {
          openingBalance += transaction.amount;
        } else if (transaction.isPayment) {
          openingBalance -= transaction.amount;
        }
        continue;
      }

      if (!date.isBefore(endExclusive)) {
        continue;
      }

      if (transaction.isCredit) {
        totalCredit += transaction.amount;
      } else if (transaction.isPayment) {
        totalPayments += transaction.amount;
      }

      entries.add(
        StatementEntry(
          transactionId: transaction.id,
          date: date,
          type: transaction.type,
          amount: transaction.amount,
          description: transaction.description,
        ),
      );
    }

    return CustomerStatement(
      customerId: customer.id,
      customerName: customer.name,
      startDate: start,
      endDate: DateTime(endDate.year, endDate.month, endDate.day),
      openingBalance: openingBalance,
      totalCredit: totalCredit,
      totalPayments: totalPayments,
      entries: List.unmodifiable(entries),
    );
  }
}
