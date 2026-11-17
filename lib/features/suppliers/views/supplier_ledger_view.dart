import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../models/supplier_entry.dart';
import '../services/supplier_statement_pdf_service.dart';
import '../viewmodels/supplier_view_model.dart';

class SupplierLedgerView extends GetView<SupplierViewModel> {
  const SupplierLedgerView({super.key});
  static final _currency = NumberFormat('#,##0.00');
  static final _date = DateFormat('dd MMM yyyy · hh:mm a');
  static final _pdf = SupplierStatementPdfService();

  String _rs(double amount) => 'Rs ${_currency.format(amount)}';

  Future<void> _entryForm(
    BuildContext context, [
    SupplierEntry? original,
  ]) async {
    final formKey = GlobalKey<FormState>();
    final amount = TextEditingController(
      text: original?.amount.toStringAsFixed(2) ?? '',
    );
    final note = TextEditingController(text: original?.description ?? '');
    var type = original?.type ?? 'purchase';
    try {
      final submit = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (dialogContext, update) => AlertDialog(
            title: Text(original == null ? 'New supplier entry' : 'Edit entry'),
            content: SizedBox(
              width: 430,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'purchase',
                            label: Text('Udhar'),
                            icon: Icon(Icons.call_received_rounded),
                          ),
                          ButtonSegment(
                            value: 'payment',
                            label: Text('Jama'),
                            icon: Icon(Icons.payments_outlined),
                          ),
                        ],
                        selected: {type},
                        onSelectionChanged: (values) =>
                            update(() => type = values.first),
                      ),
                      const SizedBox(height: 18),
                      TextFormField(
                        controller: amount,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Amount (Rs)',
                          prefixIcon: Icon(Icons.currency_rupee),
                        ),
                        validator: (text) {
                          final parsed = double.tryParse(text?.trim() ?? '');
                          if (parsed == null ||
                              !parsed.isFinite ||
                              parsed <= 0 ||
                              parsed > 999999999.99) {
                            return 'Enter a positive amount';
                          }
                          if ((parsed * 100 - (parsed * 100).round()).abs() >
                              0.000001) {
                            return 'Use at most two decimals';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: note,
                        maxLines: 2,
                        maxLength: 500,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        type == 'purchase'
                            ? 'Udhar increases what you owe the supplier.'
                            : 'Jama reduces what you owe the supplier.',
                        style: const TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() == true) {
                    Navigator.pop(dialogContext, true);
                  }
                },
                child: Text(original == null ? 'Record Entry' : 'Save Changes'),
              ),
            ],
          ),
        ),
      );
      if (submit != true) {
        return;
      }
      final success = await controller.saveEntry(
        id: original?.id,
        type: type,
        amount: double.parse(amount.text.trim()),
        description: note.text,
      );
      if (success) {
        Get.snackbar(
          'Entry saved',
          'Supplier balance updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Save failed',
          controller.error.value ?? 'Please retry.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      amount.dispose();
      note.dispose();
    }
  }

  Future<void> _delete(BuildContext context, SupplierEntry entry) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete transaction?'),
        content: const Text(
          'This will recalculate the supplier balance. '
          'Check the amount and date before deleting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmation == true && !await controller.removeEntry(entry.id)) {
      Get.snackbar(
        'Deletion failed',
        controller.error.value ?? 'Please retry.',
      );
    }
  }

  Future<void> _pdfAction(bool share) async {
    final account = controller.account;
    if (account == null) {
      return;
    }
    try {
      if (share) {
        await _pdf.share(account);
      } else {
        await _pdf.preview(account);
      }
    } catch (error) {
      Get.snackbar(
        'PDF unavailable',
        '$error',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.selected.value?.name ?? 'Supplier Khata'),
        ),
        actions: [
          IconButton(
            tooltip: 'Preview statement PDF',
            onPressed: () => _pdfAction(false),
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
          IconButton(
            tooltip: 'Share statement PDF',
            onPressed: () => _pdfAction(true),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.refreshEntries,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: controller.selected.value?.isArchived == true
            ? null
            : () => _entryForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Udhar / Jama'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Obx(() {
            final account = controller.account;
            if (account == null) {
              return const Center(child: Text('Select a supplier.'));
            }
            final items = account.runningEntries.reversed.toList();
            return RefreshIndicator(
              onRefresh: controller.refreshEntries,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33087F5B),
                          blurRadius: 20,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AMOUNT PAYABLE',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 9),
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: account.payable),
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Text(
                            _rs(value.abs()),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 30,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          account.payable > 0
                              ? 'You owe this supplier'
                              : account.payable < 0
                              ? 'Advance paid to supplier'
                              : 'Account is settled',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _totalTile(
                          'Total Udhar',
                          account.purchased,
                          Icons.call_received_rounded,
                          AppTheme.danger,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _totalTile(
                          'Total Jama',
                          account.paid,
                          Icons.payments_outlined,
                          AppTheme.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  Text(
                    'Transaction history',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (controller.loading.value)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: LinearProgressIndicator(),
                    ),
                  if (controller.error.value != null)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        controller.error.value!,
                        style: const TextStyle(color: AppTheme.danger),
                      ),
                    ),
                  const SizedBox(height: 10),
                  if (items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(30),
                      child: Center(
                        child: Text(
                          'No entries yet. Record an Udhar or Jama transaction.',
                        ),
                      ),
                    ),
                  for (final item in items)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: item.entry.isPurchase
                              ? const Color(0xFFFFE8E8)
                              : AppTheme.lightGreen,
                          child: Icon(
                            item.entry.isPurchase
                                ? Icons.call_received_rounded
                                : Icons.payments_outlined,
                            color: item.entry.isPurchase
                                ? AppTheme.danger
                                : AppTheme.success,
                          ),
                        ),
                        title: Text(
                          item.entry.isPurchase
                              ? 'Udhar · Purchase'
                              : 'Jama · Payment',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_date.format(item.entry.createdAt.toLocal())),
                            if (item.entry.description?.isNotEmpty == true)
                              Text(
                                item.entry.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              _rs(item.entry.amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: item.entry.isPurchase
                                    ? AppTheme.danger
                                    : AppTheme.success,
                              ),
                            ),
                            Text(
                              'Balance: ${_rs(item.balance)}',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          enabled: !account.supplier.isArchived,
                          onSelected: (value) => value == 'edit'
                              ? _entryForm(context, item.entry)
                              : _delete(context, item.entry),
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
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

  Widget _totalTile(String title, double amount, IconData icon, Color color) =>
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 11),
              Text(
                title,
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  _rs(amount),
                  style: TextStyle(
                    color: color,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
