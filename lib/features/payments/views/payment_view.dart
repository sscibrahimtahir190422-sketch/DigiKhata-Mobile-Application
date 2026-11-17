import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/payment_record.dart';
import '../viewmodels/payment_view_model.dart';

class PaymentView extends GetView<PaymentViewModel> {
  const PaymentView({super.key});
  static final _currency = NumberFormat('#,##0.00');
  String _money(double value) => 'Rs ${_currency.format(value)}';

  Future<void> _newPayment(BuildContext context) async {
    if (controller.customers.isEmpty) {
      Get.snackbar(
        'No customers',
        'Add an active customer before recording a payment.',
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (_) => const _PaymentFormDialog(),
    );
  }

  Future<void> _pickRange(BuildContext context) async {
    final now = DateTime.now();
    final selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange:
          controller.startDate.value != null && controller.endDate.value != null
          ? DateTimeRange(
              start: controller.startDate.value!,
              end: controller.endDate.value!,
            )
          : null,
    );
    if (selection != null) {
      controller.setRange(selection);
    }
  }

  Future<void> _delete(BuildContext context, PaymentRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete payment?'),
        content: Text(
          'Delete ${_money(record.amount)} from ${record.customerName}? This changes their account balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final ok = await controller.delete(record.id);
    if (!ok) {
      Get.snackbar(
        'Error',
        controller.error.value ?? 'Unable to delete payment',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newPayment(context),
        icon: const Icon(Icons.add),
        label: const Text('Record payment'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Obx(() {
            final records = controller.filtered;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payments received',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _money(controller.total),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${records.length} records in selected period',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    onChanged: (v) => controller.query.value = v,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search customers or notes',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickRange(context),
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          controller.startDate.value == null
                              ? 'Select dates'
                              : '${DateFormat('dd MMM').format(controller.startDate.value!)} - ${DateFormat('dd MMM yyyy').format(controller.endDate.value!)}',
                        ),
                      ),
                      if (controller.startDate.value != null)
                        TextButton(
                          onPressed: () => controller.setRange(null),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                  if (controller.loading.value)
                    const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (controller.error.value != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        controller.error.value!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  if (records.isEmpty && !controller.loading.value)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(child: Text('No payments found.')),
                    ),
                  for (final record in records)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 7,
                          ),
                          leading: const CircleAvatar(
                            backgroundColor: AppTheme.lightGreen,
                            child: Icon(
                              Icons.payments_outlined,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                          title: Text(
                            record.customerName,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text(
                            '${DateFormat('dd MMM yyyy, hh:mm a').format(record.createdAt)}${record.description == null ? '' : '\n${record.description}'}',
                          ),
                          isThreeLine: record.description != null,
                          trailing: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _money(record.amount),
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              InkWell(
                                onTap: () => _delete(context, record),
                                child: const Padding(
                                  padding: EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.delete_outline_rounded,
                                    color: AppTheme.textSecondary,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ),
      ),
    ),
  );
}

class _PaymentFormDialog extends StatefulWidget {
  const _PaymentFormDialog();
  @override
  State<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends State<_PaymentFormDialog> {
  final _form = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _notes = TextEditingController();
  String? _customerId;
  @override
  void dispose() {
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<PaymentViewModel>();
    return AlertDialog(
      title: const Text('Record payment'),
      content: SizedBox(
        width: 410,
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _customerId,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Customer'),
                items: vm.customers
                    .map(
                      (c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _customerId = v),
                validator: (v) => v == null ? 'Select a customer' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amount,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Amount (Rs)'),
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  return n == null ||
                          !n.isFinite ||
                          n <= 0 ||
                          (n * 100 - (n * 100).round()).abs() > 0.000001
                      ? 'Enter a valid amount'
                      : null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        Obx(
          () => FilledButton(
            onPressed: vm.saving.value
                ? null
                : () async {
                    if (!_form.currentState!.validate()) {
                      return;
                    }
                    final ok = await vm.create(
                      customerId: _customerId!,
                      amount: double.parse(_amount.text),
                      description: _notes.text,
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (ok) {
                      Navigator.pop(context);
                      Get.snackbar('Saved', 'Payment recorded.');
                    } else {
                      Get.snackbar(
                        'Error',
                        vm.error.value ?? 'Unable to save payment',
                      );
                    }
                  },
            child: Text(vm.saving.value ? 'Saving...' : 'Save payment'),
          ),
        ),
      ],
    );
  }
}
