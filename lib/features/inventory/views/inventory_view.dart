import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../models/product.dart';
import '../models/stock_movement.dart';
import '../viewmodels/inventory_view_model.dart';
import 'product_editor_view.dart';

class InventoryView extends GetView<InventoryViewModel> {
  const InventoryView({super.key});
  static final _money = NumberFormat('#,##0.00');
  String _rs(double n) => 'Rs ${_money.format(n)}';
  String _qty(double n) => n == n.roundToDouble()
      ? n.toStringAsFixed(0)
      : n.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');

  Future<void> _adjust(BuildContext context, Product product) async {
    final quantity = TextEditingController();
    final reason = TextEditingController();
    var increase = true;
    final form = GlobalKey<FormState>();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text('Adjust • ${product.name}'),
          content: SizedBox(
            width: 420,
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Add stock'),
                        icon: Icon(Icons.add),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Remove'),
                        icon: Icon(Icons.remove),
                      ),
                    ],
                    selected: {increase},
                    onSelectionChanged: (values) =>
                        setState(() => increase = values.first),
                  ),
                  const SizedBox(height: 18),
                  TextFormField(
                    controller: quantity,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Quantity (${product.unit})',
                      helperText: 'Available: ${_qty(product.stockQuantity)}',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (text) {
                      final n = double.tryParse(text ?? '');
                      if (n == null ||
                          !n.isFinite ||
                          n <= 0 ||
                          (n * 1000 - (n * 1000).round()).abs() > 0.000001) {
                        return 'Enter a valid quantity (up to 3 decimals)';
                      }
                      if (!increase && n > product.stockQuantity) {
                        return 'Insufficient stock';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason (required)',
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Reason is required'
                        : v.length > 200
                        ? 'Maximum 200 characters'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!form.currentState!.validate()) {
                  return;
                }
                final n = double.parse(quantity.text) * (increase ? 1 : -1);
                final success = await controller.adjust(
                  product.id,
                  n,
                  reason.text,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                if (success) {
                  Navigator.of(dialogContext).pop();
                  Get.snackbar('Updated', 'Stock updated successfully.');
                } else {
                  Get.snackbar(
                    'Stock error',
                    controller.error.value ?? 'Unable to adjust stock',
                  );
                }
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
    quantity.dispose();
    reason.dispose();
  }

  Future<void> _history(BuildContext context, Product product) async {
    final Future<List<StockMovement>> future = controller.history(product.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: 0.75,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              children: [
                Text(
                  '${product.name} • Stock history',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: FutureBuilder<List<StockMovement>>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            'Unable to load history: ${snapshot.error}',
                          ),
                        );
                      }
                      final rows = snapshot.data ?? [];
                      if (rows.isEmpty) {
                        return const Center(
                          child: Text('No stock movements yet.'),
                        );
                      }
                      return ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: (context, i) {
                          final m = rows[i];
                          return ListTile(
                            leading: Icon(
                              m.delta > 0
                                  ? Icons.add_circle_outline
                                  : Icons.remove_circle_outline,
                              color: m.delta > 0
                                  ? AppTheme.primaryGreen
                                  : AppTheme.danger,
                            ),
                            title: Text(m.reason),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy • hh:mm a',
                              ).format(m.createdAt),
                            ),
                            trailing: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${m.delta > 0 ? '+' : ''}${_qty(m.delta)} ${product.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'After: ${_qty(m.quantityAfter)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PremiumEntrance(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Inventory'),
          actions: [
            IconButton(
              onPressed: controller.load,
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(() => const ProductEditorView()),
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1120),
            child: Obx(() {
              final products = controller.filtered;
              return RefreshIndicator(
                onRefresh: controller.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
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
                            'Your inventory',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _rs(controller.inventoryValue),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const Text(
                            'Estimated stock cost value',
                            style: TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              Chip(
                                label: Text(
                                  '${controller.activeCount} products',
                                ),
                              ),
                              Chip(
                                label: Text('${controller.lowCount} low stock'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      onChanged: (v) => controller.search.value = v,
                      decoration: const InputDecoration(
                        hintText: 'Search name, SKU or category',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('Active'),
                          selected: !controller.showArchived.value,
                          onSelected: (_) {
                            controller.showArchived.value = false;
                          },
                        ),
                        FilterChip(
                          label: const Text('Archived'),
                          selected: controller.showArchived.value,
                          onSelected: (_) {
                            controller.showArchived.value = true;
                            controller.onlyLowStock.value = false;
                          },
                        ),
                        FilterChip(
                          label: const Text('Low stock'),
                          selected: controller.onlyLowStock.value,
                          onSelected: controller.showArchived.value
                              ? null
                              : (v) => controller.onlyLowStock.value = v,
                        ),
                      ],
                    ),
                    if (controller.loading.value)
                      const Padding(
                        padding: EdgeInsets.all(18),
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
                    const SizedBox(height: 10),
                    if (products.isEmpty && !controller.loading.value)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 70),
                        child: Column(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: AppTheme.primaryGreen,
                              size: 58,
                            ),
                            SizedBox(height: 12),
                            Text('No products found'),
                            SizedBox(height: 4),
                            Text(
                              'Add your first product or change the filters.',
                              style: TextStyle(color: AppTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    for (final product in products)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppTheme.lightGreen,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: AppTheme.primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            '${product.category}  •  ${product.sku ?? 'No SKU'}',
                                            style: const TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (action) {
                                        if (action == 'edit') {
                                          Get.to(
                                            () => ProductEditorView(
                                              product: product,
                                            ),
                                          );
                                        } else if (action == 'adjust') {
                                          _adjust(context, product);
                                        } else if (action == 'history') {
                                          _history(context, product);
                                        } else if (action == 'archive') {
                                          controller
                                              .archive(
                                                product.id,
                                                !product.isArchived,
                                              )
                                              .then((ok) {
                                                if (!ok) {
                                                  Get.snackbar(
                                                    'Error',
                                                    controller.error.value ??
                                                        'Update failed',
                                                  );
                                                }
                                              });
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                          value: 'edit',
                                          child: Text('Edit product'),
                                        ),
                                        if (!product.isArchived)
                                          const PopupMenuItem(
                                            value: 'adjust',
                                            child: Text('Adjust stock'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'history',
                                          child: Text('Stock history'),
                                        ),
                                        PopupMenuItem(
                                          value: 'archive',
                                          child: Text(
                                            product.isArchived
                                                ? 'Restore'
                                                : 'Archive',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 28),
                                Wrap(
                                  spacing: 22,
                                  runSpacing: 10,
                                  children: [
                                    _metric(
                                      'In stock',
                                      '${_qty(product.stockQuantity)} ${product.unit}',
                                      product.isLowStock
                                          ? AppTheme.danger
                                          : AppTheme.primaryGreen,
                                    ),
                                    _metric(
                                      'Purchase',
                                      _rs(product.purchasePrice),
                                      AppTheme.textPrimary,
                                    ),
                                    _metric(
                                      'Selling',
                                      _rs(product.sellingPrice),
                                      AppTheme.textPrimary,
                                    ),
                                  ],
                                ),
                                if (product.isLowStock)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning_amber_rounded,
                                          color: AppTheme.warning,
                                          size: 18,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Low stock — restock soon',
                                          style: TextStyle(
                                            color: AppTheme.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (!product.isArchived)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _adjust(context, product),
                                        icon: const Icon(Icons.tune_rounded),
                                        label: const Text('Adjust stock'),
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

  Widget _metric(String label, String value, Color color) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    ],
  );
}
