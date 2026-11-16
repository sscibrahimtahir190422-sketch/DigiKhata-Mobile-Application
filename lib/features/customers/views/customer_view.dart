import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../statements/bindings/customer_statement_binding.dart';
import '../../statements/views/customer_statement_view.dart';
import '../viewmodels/customer_view_model.dart';

class CustomerView extends GetView<CustomerViewModel> {
  const CustomerView({super.key});

  Future<void> _openStatement(dynamic customer) async {
    try {
      await Get.to(
        () => CustomerStatementView(),
        binding: CustomerStatementBinding(),
        arguments: {'customer': customer},
      );
    } catch (error) {
      Get.snackbar(
        'Unable to Open Statement',
        error.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String customerId,
    String customerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Customer'),
        content: Text(
          'Are you sure you want to delete $customerName? '
          'Customers with financial history cannot be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.deleteCustomer(customerId);

    if (success) {
      Get.snackbar(
        'Success',
        'Customer deleted successfully.',
        snackPosition: SnackPosition.BOTTOM,
      );
    } else {
      Get.snackbar(
        'Unable to Delete Customer',
        controller.errorMessage.value ?? 'Unable to delete customer.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  Future<void> _confirmArchive(
    BuildContext context,
    String customerId,
    String customerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.archive_outlined,
          color: AppTheme.primaryGreen,
          size: 36,
        ),
        title: const Text('Archive Customer'),
        content: Text(
          'Archive $customerName?\n\n'
          'This customer will be removed from your active customer list. '
          'Their credit and payment history will be preserved '
          'and will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.archive_outlined),
            label: const Text('Archive'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final success = await controller.archiveCustomer(customerId);

    if (success) {
      Get.snackbar(
        'Customer Archived',
        '$customerName has been moved out of your active customer list.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
    } else {
      Get.snackbar(
        'Archive Failed',
        controller.errorMessage.value ??
            'Unable to archive customer. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchController = TextEditingController();
    final searchQuery = ''.obs;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            tooltip: 'Archived Customers',
            icon: const Icon(Icons.inventory_2_outlined),
            onPressed: () {
              Get.toNamed(AppRoutes.archivedCustomers);
            },
          ),
          IconButton(
            tooltip: 'Refresh customers',
            onPressed: controller.loadCustomers,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Obx(() {
        final customers = controller.customers.toList();
        final query = searchQuery.value.trim().toLowerCase();

        final filteredCustomers = customers.where((customer) {
          return customer.name.toLowerCase().contains(query) ||
              customer.phone.toLowerCase().contains(query);
        }).toList();

        return RefreshIndicator(
          color: AppTheme.primaryGreen,
          onRefresh: controller.loadCustomers,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your Customers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${customers.length} customer'
                            '${customers.length == 1 ? '' : 's'} registered',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 46,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: searchController,
                onChanged: (value) => searchQuery.value = value,
                decoration: InputDecoration(
                  hintText: 'Search name or phone number',
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  suffixIcon: Obx(
                    () => searchQuery.value.isEmpty
                        ? const SizedBox.shrink()
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              searchController.clear();
                              searchQuery.value = '';
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (controller.isLoading.value && customers.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                )
              else if (controller.errorMessage.value != null &&
                  customers.isEmpty)
                _MessageCard(
                  icon: Icons.cloud_off_outlined,
                  title: 'Unable to load customers',
                  message: controller.errorMessage.value!,
                  actionLabel: 'Try Again',
                  onAction: controller.loadCustomers,
                )
              else if (customers.isEmpty)
                const _MessageCard(
                  icon: Icons.person_add_alt_1_rounded,
                  title: 'No customers yet',
                  message:
                      'Add your first customer to start managing their Khata.',
                )
              else if (filteredCustomers.isEmpty)
                _MessageCard(
                  icon: Icons.search_off_rounded,
                  title: 'No matching customers',
                  message: 'Try a different name or phone number.',
                  actionLabel: 'Clear Search',
                  onAction: () {
                    searchController.clear();
                    searchQuery.value = '';
                  },
                )
              else ...[
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Customer Directory',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${filteredCustomers.length} found',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...filteredCustomers.map(
                  (customer) => Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      onTap: () {
                        Get.toNamed(
                          AppRoutes.khata,
                          arguments: {
                            'customerId': customer.id,
                            'customerName': customer.name,
                          },
                        );
                      },
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppTheme.lightGreen,
                        child: Text(
                          customer.name.trim().isEmpty
                              ? '?'
                              : customer.name.trim()[0].toUpperCase(),
                          style: const TextStyle(
                            color: AppTheme.darkGreen,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(customer.phone),
                      ),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Customer actions',
                        onSelected: (action) async {
                          if (action == 'statement') {
                            await _openStatement(customer);
                          } else if (action == 'edit') {
                            await Get.toNamed(
                              AppRoutes.editCustomer,
                              arguments: customer,
                            );
                            await controller.loadCustomers();
                          } else if (action == 'archive') {
                            await _confirmArchive(
                              context,
                              customer.id,
                              customer.name,
                            );
                          } else if (action == 'delete') {
                            await _confirmDelete(
                              context,
                              customer.id,
                              customer.name,
                            );
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem<String>(
                            value: 'statement',
                            child: Row(
                              children: [
                                Icon(Icons.receipt_long_outlined),
                                SizedBox(width: 10),
                                Text('View Statement'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined),
                                SizedBox(width: 10),
                                Text('Edit customer'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'archive',
                            child: Row(
                              children: [
                                Icon(Icons.archive_outlined),
                                SizedBox(width: 10),
                                Text('Archive customer'),
                              ],
                            ),
                          ),
                          PopupMenuItem<String>(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                  color: AppTheme.danger,
                                ),
                                SizedBox(width: 10),
                                Text('Delete customer'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.toNamed(AppRoutes.addCustomer),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add Customer'),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EFEB)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppTheme.primaryGreen),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.textSecondary, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
