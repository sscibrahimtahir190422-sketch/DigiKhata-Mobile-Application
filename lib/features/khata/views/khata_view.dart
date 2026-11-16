import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../customers/repositories/customer_repositories.dart';
import '../models/khata_transaction.dart';
import '../services/transaction_pdf_service.dart';
import '../viewmodels/khata_view_model.dart';

class KhataView extends GetView<KhataViewModel> {
  const KhataView({super.key});

  @override
  Widget build(BuildContext context) {
    final arguments = Get.arguments as Map?;
    final customerName = arguments?['customerName'] as String? ?? 'Customer';

    return Scaffold(
      appBar: AppBar(
        title: Text("$customerName's Khata"),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.loadTransactions,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.transactions.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (controller.errorMessage.value != null &&
            controller.transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.cloud_off_rounded,
                    size: 48,
                    color: AppTheme.danger,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    controller.errorMessage.value!,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: controller.loadTransactions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                  ),
                ],
              ),
            ),
          );
        }

        final filteredTransactions = controller.filteredTransactions;

        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: controller.loadTransactions,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _BalanceCard(
                customerName: customerName,
                balance: controller.outstandingBalance,
              ),
              const SizedBox(height: 16),

              // Complete account totals.
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Credit',
                      amount: controller.totalCredit,
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.danger,
                      background: const Color(0xFFFFEEEE),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      title: 'Total Paid',
                      amount: controller.totalPayments,
                      icon: Icons.payments_outlined,
                      color: AppTheme.success,
                      background: AppTheme.lightGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Transaction history heading.
              const Text(
                'Transaction History',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // Date filter.
              _DateFilterCard(controller: controller),
              const SizedBox(height: 16),

              // Totals for the selected period.
              Row(
                children: [
                  Expanded(
                    child: _PeriodSummaryCard(
                      title: 'Period Credit',
                      amount: controller.filteredCredit,
                      color: AppTheme.danger,
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PeriodSummaryCard(
                      title: 'Period Paid',
                      amount: controller.filteredPayments,
                      color: AppTheme.success,
                      icon: Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      controller.dateFilterLabel,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.lightGreen,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredTransactions.length} entries',
                      style: const TextStyle(
                        color: AppTheme.darkGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (filteredTransactions.isEmpty)
                const _EmptyTransactions()
              else
                ...filteredTransactions.map(
                  (transaction) => _TransactionTile(
                    transaction: transaction,
                    onEdit: () => _editTransaction(transaction),
                    onDelete: () => _confirmDelete(transaction),
                    onShare: () => _shareReceipt(transaction),
                    onPreviewPdf: () => _previewPdfReceipt(transaction),
                    isBusy: controller.isSaving,
                  ),
                ),
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Get.toNamed(
            AppRoutes.addKhataTransaction,
            arguments: {
              'customerId': controller.customerId,
              'customerName': customerName,
            },
          );

          await controller.loadTransactions();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Entry'),
      ),
    );
  }

  Future<void> _shareReceipt(KhataTransaction transaction) async {
    try {
      final customerRepository = Get.find<CustomerRepository>();
      final customer = await customerRepository.getCustomerById(
        controller.customerId,
      );

      if (customer == null) {
        Get.snackbar(
          'Customer Not Found',
          'Unable to find this customer for the receipt.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final receipt = controller.createReceipt(
        transaction: transaction,
        customer: customer,
      );

      await SharePlus.instance.share(
        ShareParams(
          text: receipt.toShareText(),
          subject: 'DigiKhata Transaction Receipt',
        ),
      );
    } catch (_) {
      Get.snackbar(
        'Sharing Failed',
        'Unable to share the receipt. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEEEE),
        colorText: AppTheme.danger,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _previewPdfReceipt(KhataTransaction transaction) async {
    try {
      final customerRepository = Get.find<CustomerRepository>();
      final customer = await customerRepository.getCustomerById(
        controller.customerId,
      );

      if (customer == null) {
        Get.snackbar(
          'Customer Not Found',
          'Unable to find this customer for the PDF receipt.',
          snackPosition: SnackPosition.BOTTOM,
          margin: const EdgeInsets.all(16),
        );
        return;
      }

      final receipt = controller.createReceipt(
        transaction: transaction,
        customer: customer,
      );

      await TransactionPdfService().previewReceipt(receipt);
    } catch (_) {
      Get.snackbar(
        'PDF Receipt Failed',
        'Unable to create the PDF receipt. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEEEE),
        colorText: AppTheme.danger,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  Future<void> _editTransaction(KhataTransaction transaction) async {
    if (controller.isSaving.value) return;

    await Get.toNamed(
      AppRoutes.editKhataTransaction,
      arguments: {
        'customerId': controller.customerId,
        'customerName': Get.arguments is Map
            ? (Get.arguments as Map)['customerName']
            : 'Customer',
        'transaction': transaction,
      },
    );

    await controller.loadTransactions();
  }

  Future<void> _confirmDelete(KhataTransaction transaction) async {
    if (controller.isSaving.value) return;

    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        icon: const Icon(
          Icons.delete_outline_rounded,
          color: AppTheme.danger,
          size: 32,
        ),
        title: const Text('Delete Transaction?'),
        content: Text(
          'Are you sure you want to delete this '
          '${transaction.isCredit ? 'credit entry' : 'payment'} of '
          'Rs. ${transaction.amount.toStringAsFixed(2)}? '
          'This will update the customer balance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    final success = await controller.deleteTransaction(
      transactionId: transaction.id,
    );

    if (success) {
      Get.snackbar(
        'Transaction Deleted',
        'The transaction was deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.lightGreen,
        colorText: AppTheme.darkGreen,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        controller.errorMessage.value ?? 'Unable to delete transaction.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEEEE),
        colorText: AppTheme.danger,
        margin: const EdgeInsets.all(16),
      );
    }
  }
}

class _DateFilterCard extends StatelessWidget {
  const _DateFilterCard({required this.controller});

  final KhataViewModel controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                color: AppTheme.primaryGreen,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Filter by date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _filterChip(
                  label: 'All time',
                  filter: TransactionDateFilter.allTime,
                ),
                _filterChip(
                  label: 'Today',
                  filter: TransactionDateFilter.today,
                ),
                _filterChip(
                  label: '7 days',
                  filter: TransactionDateFilter.last7Days,
                ),
                _filterChip(
                  label: '30 days',
                  filter: TransactionDateFilter.last30Days,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _selectCustomRange(context),
              icon: const Icon(Icons.date_range_rounded),
              label: Obx(
                () => Text(
                  controller.dateFilter.value == TransactionDateFilter.custom
                      ? controller.dateFilterLabel
                      : 'Choose custom date range',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Obx(() {
            if (controller.dateFilter.value != TransactionDateFilter.custom) {
              return const SizedBox.shrink();
            }

            return Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () =>
                    controller.setDateFilter(TransactionDateFilter.allTime),
                icon: const Icon(Icons.clear_rounded, size: 18),
                label: const Text('Clear date filter'),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required TransactionDateFilter filter,
  }) {
    final selected = controller.dateFilter.value == filter;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => controller.setDateFilter(filter),
      selectedColor: AppTheme.lightGreen,
      checkmarkColor: AppTheme.darkGreen,
      labelStyle: TextStyle(
        color: selected ? AppTheme.darkGreen : AppTheme.textSecondary,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected
            ? AppTheme.primaryGreen.withValues(alpha: 0.35)
            : const Color(0xFFE8EFEB),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  Future<void> _selectCustomRange(BuildContext context) async {
    final now = DateTime.now();
    final initialStart =
        controller.customStartDate.value ??
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
    final initialEnd = controller.customEndDate.value ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
      initialDateRange: DateTimeRange(
        start: initialStart.isAfter(initialEnd) ? initialEnd : initialStart,
        end: initialEnd,
      ),
      helpText: 'Select transaction date range',
      saveText: 'Apply',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppTheme.primaryGreen,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    await controller.selectCustomDateRange(
      start: picked.start,
      end: picked.end,
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.customerName, required this.balance});

  final String customerName;
  final double balance;

  @override
  Widget build(BuildContext context) {
    final hasDue = balance > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  customerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.white70,
                size: 22,
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            hasDue ? 'Outstanding Balance' : 'Account Balance',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs. ${balance.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasDue
                      ? Icons.schedule_rounded
                      : Icons.check_circle_outline_rounded,
                  color: Colors.white,
                  size: 17,
                ),
                const SizedBox(width: 7),
                Text(
                  hasDue ? 'Payment pending' : 'No outstanding dues',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 23),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rs. ${amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PeriodSummaryCard extends StatelessWidget {
  const _PeriodSummaryCard({
    required this.title,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String title;
  final double amount;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Rs. ${amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: AppTheme.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try another date range or add a new credit or payment.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
    required this.onPreviewPdf,
    required this.isBusy,
  });

  final KhataTransaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onPreviewPdf;
  final RxBool isBusy;

  @override
  Widget build(BuildContext context) {
    final isCredit = transaction.isCredit;
    final date = transaction.createdAt.toLocal();
    final color = isCredit ? AppTheme.danger : AppTheme.success;
    final background = isCredit ? const Color(0xFFFFEEEE) : AppTheme.lightGreen;

    final formattedDate =
        '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';

    final formattedTime =
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';

    final description = transaction.description?.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isCredit
                    ? Icons.shopping_bag_outlined
                    : Icons.payments_outlined,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCredit ? 'Credit Added' : 'Payment Received',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$formattedDate • $formattedTime',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                PopupMenuButton<String>(
                  tooltip: 'Transaction options',
                  enabled: !isBusy.value,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 140),
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    color: AppTheme.textSecondary,
                    size: 22,
                  ),
                  onSelected: (value) {
                    if (value == 'share') {
                      onShare();
                    } else if (value == 'pdf') {
                      onPreviewPdf();
                    } else if (value == 'edit') {
                      onEdit();
                    } else if (value == 'delete') {
                      onDelete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share_outlined, size: 19),
                          SizedBox(width: 10),
                          Text('Share Receipt'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'pdf',
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, size: 19),
                          SizedBox(width: 10),
                          Text('Preview PDF Receipt'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 19),
                          SizedBox(width: 10),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete_outline_rounded,
                            size: 19,
                            color: AppTheme.danger,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Delete',
                            style: TextStyle(color: AppTheme.danger),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${isCredit ? '+' : '-'} Rs. '
                  '${transaction.amount.toStringAsFixed(2)}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
