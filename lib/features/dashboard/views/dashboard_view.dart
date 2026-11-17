import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/brand_mark.dart';
import '../../../core/services/locale_preferences.dart';
import '../models/dashboard_summary.dart';
import '../viewmodels/dashboard_view_model.dart';

/// Premium home experience. All amounts come from the existing DashboardViewModel.
class DashboardView extends GetView<DashboardViewModel> {
  const DashboardView({super.key});
  static final NumberFormat _format = NumberFormat('#,##0.00');
  static String money(double amount) => 'Rs ${_format.format(amount)}';
  static const _forest = Color(0xFF063F33);
  static const _mint = Color(0xFFB6F3D3);
  static const _gold = Color(0xFFF4C976);

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (index) {
          switch (index) {
            case 1:
              Get.toNamed(AppRoutes.customers);
              break;
            case 2:
              Get.toNamed(AppRoutes.inventory);
              break;
            case 3:
              Get.toNamed(AppRoutes.reports);
              break;
            case 4:
              Get.toNamed(AppRoutes.settings);
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Reports',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          if (controller.isLoading.value && !controller.hasLoadedSuccessfully) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(24),
                  children: const [
                    PremiumSkeleton(height: 54, width: 220, radius: 18),
                    SizedBox(height: 26),
                    PremiumSkeleton(height: 195, radius: 28),
                    SizedBox(height: 30),
                    PremiumSkeleton(height: 26, width: 170),
                    SizedBox(height: 18),
                    PremiumSkeleton(height: 105, radius: 22),
                    SizedBox(height: 14),
                    PremiumSkeleton(height: 105, radius: 22),
                  ],
                ),
              ),
            );
          }
          if (!controller.hasLoadedSuccessfully &&
              controller.errorMessage.value != null) {
            return _errorState(controller.errorMessage.value!);
          }
          final summary = controller.summary.value;
          return RefreshIndicator(
            onRefresh: controller.loadDashboard,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1060),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
                  children: [
                    _header(context),
                    const SizedBox(height: 25),
                    _welcome(),
                    const SizedBox(height: 20),
                    _balanceCard(summary),
                    const SizedBox(height: 26),
                    _section(
                      'Quick actions',
                      'Everything you need, one tap away',
                    ),
                    const SizedBox(height: 15),
                    _quickActions(),
                    const SizedBox(height: 28),
                    _section(
                      'Today at a glance',
                      'Your business, in real time',
                    ),
                    const SizedBox(height: 14),
                    _metrics(summary),
                    const SizedBox(height: 27),
                    _section(
                      'Business workspace',
                      'Manage more than just credit',
                    ),
                    const SizedBox(height: 14),
                    _workspace(),
                    if (controller.errorMessage.value != null) ...[
                      const SizedBox(height: 18),
                      Material(
                        color: const Color(0xFFFFF4E8),
                        borderRadius: BorderRadius.circular(16),
                        child: ListTile(
                          leading: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF9D6117),
                          ),
                          title: Text(controller.errorMessage.value!),
                          trailing: IconButton(
                            onPressed: controller.loadDashboard,
                            icon: const Icon(Icons.refresh),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    ),
  );

  Widget _errorState(String message) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 52,
            color: AppTheme.primaryGreen,
          ),
          const SizedBox(height: 14),
          const Text(
            'Unable to load your business',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: controller.loadDashboard,
            child: const Text('Try again'),
          ),
        ],
      ),
    ),
  );

  Widget _header(BuildContext context) => Row(
    children: [
      const DigiKhataBrandMark(size: 48),
      const SizedBox(width: 11),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DigiKhata',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
            Text(
              'YOUR BUSINESS, BEAUTIFULLY MANAGED',
              style: TextStyle(
                fontSize: 9,
                letterSpacing: 1.05,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
      _roundIcon(Icons.translate_rounded, 'Language', () async {
        final selection = await Get.dialog<String>(
          SimpleDialog(
            title: const Text('Choose language'),
            children: [
              SimpleDialogOption(
                onPressed: () => Get.back(result: 'en'),
                child: const Text('English'),
              ),
              SimpleDialogOption(
                onPressed: () => Get.back(result: 'ur'),
                child: const Text('اردو'),
              ),
            ],
          ),
        );
        if (selection != null) {
          try {
            await LocalePreferences.change(Supabase.instance.client, selection);
          } catch (e) {
            Get.snackbar('Language update failed', '$e');
          }
        }
      }),
      const SizedBox(width: 8),
      _roundIcon(Icons.refresh_rounded, 'Refresh', controller.loadDashboard),
    ],
  );

  Widget _roundIcon(IconData icon, String tooltip, VoidCallback onPressed) =>
      Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE4EAE5)),
        ),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed,
          icon: Icon(icon, size: 20, color: _forest),
        ),
      );

  Widget _welcome() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        DateFormat('EEEE, d MMMM').format(DateTime.now()).toUpperCase(),
        style: const TextStyle(
          color: AppTheme.primaryGreen,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          fontSize: 11,
        ),
      ),
      const SizedBox(height: 7),
      const Text(
        'Your business overview',
        style: TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 28,
          letterSpacing: -1.2,
          color: AppTheme.textPrimary,
        ),
      ),
      const SizedBox(height: 4),
      const Text(
        'Every rupee, every customer, all in one place.',
        style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
      ),
    ],
  );

  Widget _balanceCard(DashboardSummary s) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0A7756), _forest],
      ),
      borderRadius: BorderRadius.circular(28),
      boxShadow: [
        BoxShadow(
          color: _forest.withValues(alpha: 0.19),
          blurRadius: 26,
          offset: const Offset(0, 13),
        ),
      ],
    ),
    child: Stack(
      children: [
        Positioned(
          right: -65,
          top: -100,
          child: Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.09),
                width: 36,
              ),
            ),
          ),
        ),
        Positioned(
          right: -30,
          bottom: -120,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _mint.withValues(alpha: 0.06),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Text(
                      'TOTAL CUSTOMER BALANCE',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: _gold,
                    size: 22,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: s.totalReceivables),
                duration: const Duration(milliseconds: 850),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    money(value),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                s.totalReceivables > 0
                    ? 'Amount to collect from customers'
                    : s.totalReceivables < 0
                    ? 'Net customer advance balance'
                    : 'All customer accounts are settled',
                style: const TextStyle(color: Color(0xFFCCE9DD), fontSize: 12),
              ),
              const SizedBox(height: 23),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people_alt_outlined,
                      color: _mint,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.customerCount} customers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => Get.toNamed(AppRoutes.customers),
                      child: const Row(
                        children: [
                          Text(
                            'View accounts',
                            style: TextStyle(
                              color: _mint,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward_rounded,
                            color: _mint,
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _section(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
      ),
    ],
  );

  Widget _quickActions() => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - 12) / 2;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: _quickTile(
              'Add customer',
              'New account',
              Icons.person_add_alt_1_rounded,
              const Color(0xFF0B8060),
              AppRoutes.addCustomer,
            ),
          ),
          SizedBox(
            width: width,
            child: _quickTile(
              'Record Udhar',
              'Credit entry',
              Icons.north_east_rounded,
              const Color(0xFFBD7830),
              AppRoutes.customers,
            ),
          ),
          SizedBox(
            width: width,
            child: _quickTile(
              'Receive Jama',
              'Record payment',
              Icons.south_west_rounded,
              const Color(0xFF217A9A),
              AppRoutes.payments,
            ),
          ),
          SizedBox(
            width: width,
            child: _quickTile(
              'Manage stock',
              'Products & quantity',
              Icons.inventory_2_rounded,
              const Color(0xFF6E5FA8),
              AppRoutes.inventory,
            ),
          ),
        ],
      );
    },
  );

  Widget _quickTile(
    String title,
    String subtitle,
    IconData icon,
    Color accent,
    String route,
  ) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Get.toNamed(route),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: accent, size: 23),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_outward_rounded,
                  size: 17,
                  color: Color(0xFF9AABA1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _metrics(DashboardSummary s) => LayoutBuilder(
    builder: (context, constraints) {
      final count = constraints.maxWidth >= 850 ? 4 : 2;
      final width = (constraints.maxWidth - (count - 1) * 12) / count;
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SizedBox(
            width: width,
            child: _metric(
              'Today’s Udhar',
              s.todaySales,
              Icons.trending_up_rounded,
              const Color(0xFFBD7830),
            ),
          ),
          SizedBox(
            width: width,
            child: _metric(
              'Today’s Jama',
              s.todayPayments,
              Icons.south_west_rounded,
              const Color(0xFF087B5B),
            ),
          ),
          SizedBox(
            width: width,
            child: _metric(
              'Supplier dues',
              s.supplierPayables,
              Icons.local_shipping_outlined,
              const Color(0xFF7C62A6),
            ),
          ),
          SizedBox(
            width: width,
            child: _metric(
              'Stock value',
              s.stockValue,
              Icons.inventory_2_outlined,
              const Color(0xFF237C99),
            ),
          ),
        ],
      );
    },
  );

  Widget _metric(String label, double amount, IconData icon, Color accent) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE8EEE8)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: accent),
                const Spacer(),
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 7),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(amount),
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _workspace() => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFE8EEE8)),
    ),
    child: Column(
      children: [
        _workspaceRow(
          'Customer ledger',
          'View balances and transactions',
          Icons.menu_book_outlined,
          AppRoutes.customers,
        ),
        const Divider(indent: 66, endIndent: 16),
        _workspaceRow(
          'Suppliers',
          'Purchases and payables',
          Icons.local_shipping_outlined,
          AppRoutes.suppliers,
        ),
        const Divider(indent: 66, endIndent: 16),
        _workspaceRow(
          'Business reports',
          'Track performance and trends',
          Icons.insert_chart_outlined_rounded,
          AppRoutes.reports,
        ),
      ],
    ),
  );

  Widget _workspaceRow(
    String title,
    String subtitle,
    IconData icon,
    String route,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
    leading: Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: AppTheme.primaryGreen, size: 21),
    ),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
    ),
    trailing: const Icon(
      Icons.chevron_right_rounded,
      color: AppTheme.textSecondary,
    ),
    onTap: () => Get.toNamed(route),
  );
}
