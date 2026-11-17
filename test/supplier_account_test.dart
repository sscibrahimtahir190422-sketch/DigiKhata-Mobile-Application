import 'package:flutter_test/flutter_test.dart';
import 'package:digikhata/features/suppliers/models/supplier.dart';
import 'package:digikhata/features/suppliers/models/supplier_account.dart';
import 'package:digikhata/features/suppliers/models/supplier_entry.dart';

void main() {
  const supplier = Supplier(id: 's1', name: 'Wholesale Store', phone: '');
  final base = DateTime.utc(2026, 11, 16, 10);

  test('Udhar purchases increase payable; Jama payments decrease it', () {
    final account = SupplierAccount(
      supplier: supplier,
      entries: [
        SupplierEntry(
          id: 'b',
          supplierId: 's1',
          type: 'payment',
          amount: 50,
          createdAt: base.add(const Duration(hours: 1)),
        ),
        SupplierEntry(
          id: 'a',
          supplierId: 's1',
          type: 'purchase',
          amount: 200,
          createdAt: base,
        ),
      ],
    );
    expect(account.purchased, 200);
    expect(account.paid, 50);
    expect(account.payable, 150);
    final running = account.runningEntries;
    expect(running.map((e) => e.entry.id).toList(), ['a', 'b']);
    expect(running.map((e) => e.balance).toList(), [200, 150]);
  });

  test('Extra Jama appears as supplier advance (negative payable)', () {
    final account = SupplierAccount(
      supplier: supplier,
      entries: [
        SupplierEntry(
          id: 'c',
          supplierId: 's1',
          type: 'payment',
          amount: 120,
          createdAt: base,
        ),
      ],
    );
    expect(account.payable, -120);
  });

  test('Supplier JSON preserves archived state and address', () {
    final parsed = Supplier.fromJson({
      'id': 's2',
      'name': 'Supplier B',
      'phone': '0300',
      'address': 'Main market',
      'is_archived': true,
    });
    expect(parsed.isArchived, true);
    expect(parsed.address, 'Main market');
  });
}
