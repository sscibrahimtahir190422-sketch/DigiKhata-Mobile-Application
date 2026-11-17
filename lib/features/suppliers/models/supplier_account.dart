import 'supplier.dart';
import 'supplier_entry.dart';

class SupplierAccount {
  const SupplierAccount({required this.supplier, required this.entries});

  final Supplier supplier;
  final List<SupplierEntry> entries;

  double get purchased => entries
      .where((entry) => entry.isPurchase)
      .fold(0, (double total, entry) => total + entry.amount);
  double get paid => entries
      .where((entry) => entry.isPayment)
      .fold(0, (double total, entry) => total + entry.amount);
  double get payable => purchased - paid;

  /// Returns historical running balance for the sorted entry list.
  List<({SupplierEntry entry, double balance})> get runningEntries {
    var balance = 0.0;
    final sorted = entries.toList()
      ..sort((a, b) {
        final dateOrder = a.createdAt.compareTo(b.createdAt);
        return dateOrder == 0 ? a.id.compareTo(b.id) : dateOrder;
      });
    return [
      for (final entry in sorted)
        (entry: entry, balance: balance += entry.signedAmount),
    ];
  }
}
