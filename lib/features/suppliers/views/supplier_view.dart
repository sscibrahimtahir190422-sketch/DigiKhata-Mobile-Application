import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../models/supplier.dart';
import '../viewmodels/supplier_view_model.dart';
import 'supplier_ledger_view.dart';

class SupplierView extends GetView<SupplierViewModel> {
  const SupplierView({super.key});

  Future<void> _edit(BuildContext context, [Supplier? supplier]) async {
    final key = GlobalKey<FormState>();
    final name = TextEditingController(text: supplier?.name ?? '');
    final phone = TextEditingController(text: supplier?.phone ?? '');
    final address = TextEditingController(text: supplier?.address ?? '');
    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(supplier == null ? 'Add Supplier' : 'Edit Supplier'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: key,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      maxLength: 150,
                      decoration: const InputDecoration(
                        labelText: 'Supplier name',
                      ),
                      validator: (value) =>
                          value?.trim().isEmpty == true || value == null
                          ? 'Supplier name required'
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Phone (optional)',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: address,
                      maxLines: 2,
                      maxLength: 500,
                      decoration: const InputDecoration(
                        labelText: 'Address (optional)',
                      ),
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
                if (key.currentState?.validate() == true) {
                  Navigator.pop(dialogContext, true);
                }
              },
              child: const Text('Save Supplier'),
            ),
          ],
        ),
      );
      if (result != true) {
        return;
      }
      final success = await controller.saveSupplier(
        id: supplier?.id,
        name: name.text,
        phone: phone.text,
        address: address.text,
      );
      if (success) {
        Get.snackbar(
          'Saved',
          'Supplier details updated.',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Unable to save',
          controller.error.value ?? 'Please retry.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } finally {
      name.dispose();
      phone.dispose();
      address.dispose();
    }
  }

  Future<void> _archive(BuildContext context, Supplier supplier) async {
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          supplier.isArchived ? 'Restore supplier' : 'Archive supplier',
        ),
        content: Text(
          supplier.isArchived
              ? 'Restore ${supplier.name} to your active suppliers?'
              : 'Archive ${supplier.name}? Their financial history will remain intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(supplier.isArchived ? 'Restore' : 'Archive'),
          ),
        ],
      ),
    );
    if (confirmation != true) {
      return;
    }
    if (!await controller.archiveSupplier(supplier.id, !supplier.isArchived)) {
      Get.snackbar('Error', controller.error.value ?? 'Please retry.');
    }
  }

  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: controller.load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Supplier'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryGreen, AppTheme.darkGreen],
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
                            color: Colors.white,
                            size: 36,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Supplier Khata',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Obx(
                                  () => Text(
                                    '${controller.suppliers.length} active suppliers • Udhar & Jama',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      onChanged: (value) => controller.query.value = value,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText: 'Search suppliers or phone numbers',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(
                      () => SwitchListTile.adaptive(
                        value: controller.showArchived.value,
                        onChanged: (value) =>
                            controller.showArchived.value = value,
                        title: const Text('Show archived suppliers'),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Obx(() {
                  if (controller.loading.value &&
                      controller.suppliers.isEmpty &&
                      controller.archived.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final rows = controller.filtered;
                  return RefreshIndicator(
                    onRefresh: controller.load,
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: rows.isEmpty ? 1 : rows.length,
                      itemBuilder: (context, index) {
                        if (rows.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(28),
                            child: Center(
                              child: Text(
                                controller.error.value ??
                                    'No suppliers found. Add your first supplier to start.',
                              ),
                            ),
                          );
                        }
                        final supplier = rows[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: AppTheme.lightGreen,
                              child: Icon(
                                Icons.store_mall_directory_outlined,
                                color: AppTheme.darkGreen,
                              ),
                            ),
                            title: Text(
                              supplier.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              supplier.phone.isEmpty
                                  ? 'Tap to view supplier khata'
                                  : supplier.phone,
                            ),
                            onTap: () async {
                              await controller.open(supplier);
                              if (controller.selected.value != null) {
                                await Get.to(() => const SupplierLedgerView());
                              }
                            },
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) {
                                if (action == 'edit') {
                                  _edit(context, supplier);
                                }
                                if (action == 'archive') {
                                  _archive(context, supplier);
                                }
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                PopupMenuItem(
                                  value: 'archive',
                                  child: Text(
                                    supplier.isArchived ? 'Restore' : 'Archive',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
