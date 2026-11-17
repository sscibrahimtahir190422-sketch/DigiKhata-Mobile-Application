import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/business_report.dart';
import '../services/business_report_pdf_service.dart';
import '../viewmodels/report_view_model.dart';

class ReportView extends GetView<ReportViewModel> {
  ReportView({super.key});
  final BusinessReportPdfService _pdf = BusinessReportPdfService();
  final _currency = NumberFormat('#,##0.00');
  String _rs(double value) => 'Rs ${_currency.format(value)}';
  String _date(DateTime v) => DateFormat('dd MMM yyyy').format(v);

  Future<void> _select(BuildContext context) async {
    final selection = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: controller.start.value,
        end: controller.end.value,
      ),
    );
    if (selection != null) {
      await controller.setRange(selection.start, selection.end);
    }
  }

  Future<void> _export(bool share) async {
    final report = controller.report.value;
    if (report == null) {
      return;
    }
    try {
      if (share) {
        await _pdf.share(report);
      } else {
        await _pdf.preview(report);
      }
    } catch (e) {
      Get.snackbar(
        'PDF error',
        'Unable to ${share ? 'share' : 'preview'} report: $e',
      );
    }
  }

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Business Reports'),
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'Preview PDF',
              onPressed:
                  controller.report.value == null || controller.loading.value
                  ? null
                  : () => _export(false),
              icon: const Icon(Icons.picture_as_pdf_outlined),
            ),
          ),
          Obx(
            () => IconButton(
              tooltip: 'Share PDF',
              onPressed:
                  controller.report.value == null || controller.loading.value
                  ? null
                  : () => _export(true),
              icon: const Icon(Icons.share_outlined),
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Obx(() {
            final report = controller.report.value;
            return RefreshIndicator(
              onRefresh: controller.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                children: [
                  Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppTheme.lightGreen,
                        child: Icon(
                          Icons.date_range_rounded,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                      title: const Text(
                        'Reporting period',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        '${_date(controller.start.value)} – ${_date(controller.end.value)}',
                      ),
                      trailing: const Icon(Icons.edit_calendar_outlined),
                      onTap: () => _select(context),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (controller.loading.value)
                    const Padding(
                      padding: EdgeInsets.all(25),
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
                  if (report != null) ...[
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
                            'Net outstanding',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rs(report.outstanding),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 31,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'All recorded credit minus all recorded payments',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) => Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _card(
                            'Period credit',
                            _rs(report.credit),
                            Icons.trending_up_rounded,
                            AppTheme.primaryGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Period payments',
                            _rs(report.payments),
                            Icons.payments_outlined,
                            Colors.blue.shade700,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Net account movement',
                            _rs(report.netActivity),
                            Icons.account_balance_wallet_outlined,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Inventory cost value',
                            _rs(report.inventoryCostValue),
                            Icons.inventory_2_outlined,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Active customers',
                            '${report.customerCount}',
                            Icons.people_outline_rounded,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Active products',
                            '${report.productCount}',
                            Icons.widgets_outlined,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Supplier payables',
                            _rs(report.supplierPayable),
                            Icons.local_shipping_outlined,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                          _card(
                            'Active suppliers',
                            '${report.supplierCount}',
                            Icons.store_outlined,
                            AppTheme.darkGreen,
                            constraints.maxWidth,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Daily Activity',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Credit and payments recorded in the selected date range.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    if (report.daily.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(
                          child: Text('No entries in this date range.'),
                        ),
                      ),
                    for (final d in report.daily.reversed) _dayTile(d, report),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    ),
  );

  Widget _card(
    String title,
    String value,
    IconData icon,
    Color accent,
    double width,
  ) => SizedBox(
    width: width >= 600 ? (width - 12) / 2 : width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: accent),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 21,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _dayTile(DailyBusinessTotal d, BusinessReport report) {
    final max = report.daily.fold<double>(1, (m, v) {
      final n = v.credit > v.payments ? v.credit : v.payments;
      return n > m ? n : m;
    });
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _date(d.day),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _bar('Credit', d.credit, max, AppTheme.primaryGreen),
            const SizedBox(height: 8),
            _bar('Payments', d.payments, max, Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _bar(String label, double amount, double max, Color color) => Column(
    children: [
      Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
          Text(
            _rs(amount),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LinearProgressIndicator(
          value: (amount / max).clamp(0, 1).toDouble(),
          minHeight: 8,
          color: color,
          backgroundColor: AppTheme.lightGreen,
        ),
      ),
    ],
  );
}
