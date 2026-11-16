import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/customer_view_model.dart';

class ArchivedCustomersView extends StatefulWidget {
  const ArchivedCustomersView({super.key});

  @override
  State<ArchivedCustomersView> createState() => _ArchivedCustomersViewState();
}

class _ArchivedCustomersViewState extends State<ArchivedCustomersView> {
  late final CustomerViewModel controller;

  @override
  void initState() {
    super.initState();
    controller = Get.find<CustomerViewModel>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.loadArchivedCustomers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Archived Customers')),
      body: Obx(() {
        if (controller.isArchivedLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final error = controller.archivedErrorMessage.value;

        if (error != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 42),
                  const SizedBox(height: 12),
                  Text(error, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: controller.loadArchivedCustomers,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (controller.archivedCustomers.isEmpty) {
          return RefreshIndicator(
            onRefresh: controller.loadArchivedCustomers,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 140),
                Icon(Icons.archive_outlined, size: 56),
                SizedBox(height: 16),
                Center(child: Text('No archived customers')),
                SizedBox(height: 8),
                Center(child: Text('Customers you archive will appear here.')),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadArchivedCustomers,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: controller.archivedCustomers.length,
            itemBuilder: (context, index) {
              final customer = controller.archivedCustomers[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.12,
                    ),
                    child: Icon(
                      Icons.person_outline,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.phone),
                  trailing: IconButton(
                    tooltip: 'Restore customer',
                    icon: const Icon(Icons.unarchive_outlined),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Restore customer?'),
                          content: Text(
                            'Restore ${customer.name} to your customer list?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Restore'),
                            ),
                          ],
                        ),
                      );

                      if (confirmed != true) return;

                      final success = await controller.restoreCustomer(
                        customer.id,
                      );

                      if (!context.mounted) return;

                      Get.snackbar(
                        success ? 'Restored' : 'Error',
                        success
                            ? '${customer.name} restored successfully.'
                            : controller.archivedErrorMessage.value ??
                                  'Unable to restore customer.',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
                  ),
                ),
              );
            },
          ),
        );
      }),
    );
  }
}
