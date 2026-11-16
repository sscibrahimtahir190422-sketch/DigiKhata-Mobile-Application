import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../khata/services/customer_statement_pdf_service.dart';
import '../models/customer_statement.dart';
import '../models/statement_entry.dart';
import '../viewmodels/customer_statement_view_model.dart';

class CustomerStatementView extends GetView<CustomerStatementViewModel> {
  CustomerStatementView({super.key});

  final CustomerStatementPdfService _pdfService = CustomerStatementPdfService();

  Future<void> _selectDateRange(BuildContext context) async {
    final now = DateTime.now();

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now,
      initialDateRange: DateTimeRange(
        start: controller.startDate.value,
        end: controller.endDate.value.isAfter(now)
            ? now
            : controller.endDate.value,
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: AppTheme.primaryGreen),
          ),
          child: child!,
        );
      },
    );

    if (selectedRange != null) {
      await controller.updateDateRange(
        start: selectedRange.start,
        end: selectedRange.end,
      );
    }
  }

  Future<void> _exportStatementPdf() async {
    final statement = controller.statement.value;

    if (statement == null) {
      Get.snackbar(
        'No Statement',
        'Please load a customer statement first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _pdfService.previewStatement(statement);
    } catch (error) {
      Get.snackbar(
        'PDF Export Failed',
        'Unable to generate the statement PDF. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _shareStatementPdf() async {
    final statement = controller.statement.value;

    if (statement == null) {
      Get.snackbar(
        'No Statement',
        'Please load a customer statement first.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      await _pdfService.shareStatement(statement);
    } catch (error) {
      Get.snackbar(
        'Sharing Failed',
        'Unable to share the statement PDF. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _formatCurrency(double amount) {
    return 'Rs ${NumberFormat('#,##0.00').format(amount)}';
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Statement'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Export statement PDF',
              onPressed:
                  controller.isLoading.value ||
                      controller.statement.value == null
                  ? null
                  : _exportStatementPdf,
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Share Statement PDF',
              onPressed:
                  controller.isLoading.value ||
                      controller.statement.value == null
                  ? null
                  : _shareStatementPdf,
              icon: const Icon(Icons.share_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Refresh statement',
            onPressed: controller.loadStatement,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final statement = controller.statement.value;

        if (controller.isLoading.value && statement == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryGreen),
          );
        }

        if (controller.errorMessage.value != null && statement == null) {
          return _buildError(controller.errorMessage.value!);
        }

        if (statement == null) {
          return _buildError('No statement is available.');
        }

        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: controller.loadStatement,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCustomerHeader(statement),
              const SizedBox(height: 16),
              _buildDateRangeCard(context),
              const SizedBox(height: 16),
              _buildBalanceCard(statement),
              const SizedBox(height: 16),
              _buildSummaryCards(statement),
              const SizedBox(height: 24),
              _buildTransactionHeading(statement),
              const SizedBox(height: 12),
              if (statement.entries.isEmpty)
                _buildEmptyTransactions()
              else
                ...statement.entries.reversed.map(
                  (entry) => _buildTransactionTile(entry),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCustomerHeader(CustomerStatement statement) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(
              Icons.person_outline_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STATEMENT FOR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  statement.customerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_formatDate(statement.startDate)} - '
                  '${_formatDate(statement.endDate)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangeCard(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppTheme.lightGreen,
          child: Icon(Icons.calendar_month_outlined, color: AppTheme.darkGreen),
        ),
        title: const Text(
          'Statement Period',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Obx(
          () => Text(
            '${_formatDate(controller.startDate.value)} - '
            '${_formatDate(controller.endDate.value)}',
          ),
        ),
        trailing: const Icon(Icons.edit_calendar_outlined),
        onTap: () => _selectDateRange(context),
      ),
    );
  }

  Widget _buildBalanceCard(CustomerStatement statement) {
    final balance = statement.closingBalance;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2ECE6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CLOSING BALANCE',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatCurrency(balance.abs()),
            style: TextStyle(
              color: balance > 0
                  ? AppTheme.primaryGreen
                  : balance < 0
                  ? Colors.red.shade700
                  : AppTheme.textPrimary,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balance > 0
                ? 'Amount the customer owes'
                : balance < 0
                ? 'Customer has an advance balance'
                : 'Account is settled',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const Divider(height: 28),
          _balanceRow('Opening balance', statement.openingBalance),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(CustomerStatement statement) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            title: 'Credit',
            amount: statement.totalCredit,
            icon: Icons.trending_up_rounded,
            color: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            title: 'Payments',
            amount: statement.totalPayments,
            icon: Icons.payments_outlined,
            color: Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 25),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              _formatCurrency(amount),
              style: TextStyle(
                color: color,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _balanceRow(String title, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildTransactionHeading(CustomerStatement statement) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Transaction History',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '${statement.entries.length} entries',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTransactionTile(StatementEntry entry) {
    final isCredit = entry.isCredit;
    final color = isCredit ? AppTheme.primaryGreen : Colors.blue.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(
            isCredit
                ? Icons.add_shopping_cart_rounded
                : Icons.payments_outlined,
            color: color,
          ),
        ),
        title: Text(
          isCredit ? 'Credit' : 'Payment',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_formatDate(entry.date)),
              if (entry.description != null &&
                  entry.description!.trim().isNotEmpty)
                Text(
                  entry.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
        trailing: Text(
          '${isCredit ? '+' : '-'}${_formatCurrency(entry.amount)}',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyTransactions() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 44,
            color: AppTheme.primaryGreen,
          ),
          SizedBox(height: 12),
          Text(
            'No transactions in this period',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 6),
          Text(
            'Try selecting a different date range.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 48,
              color: AppTheme.primaryGreen,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load statement',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: controller.loadStatement,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
