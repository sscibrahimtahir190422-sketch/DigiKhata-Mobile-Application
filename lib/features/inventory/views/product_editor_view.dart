import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../models/product.dart';
import '../viewmodels/inventory_view_model.dart';

class ProductEditorView extends StatefulWidget {
  const ProductEditorView({super.key, this.product});
  final Product? product;
  @override
  State<ProductEditorView> createState() => _ProductEditorViewState();
}

class _ProductEditorViewState extends State<ProductEditorView> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController name,
      sku,
      category,
      unit,
      description,
      purchase,
      selling,
      threshold;
  @override
  void initState() {
    super.initState();
    final p = widget.product;
    name = TextEditingController(text: p?.name ?? '');
    sku = TextEditingController(text: p?.sku ?? '');
    category = TextEditingController(text: p?.category ?? 'General');
    unit = TextEditingController(text: p?.unit ?? 'pcs');
    description = TextEditingController(text: p?.description ?? '');
    purchase = TextEditingController(
      text: p?.purchasePrice.toStringAsFixed(2) ?? '0',
    );
    selling = TextEditingController(
      text: p?.sellingPrice.toStringAsFixed(2) ?? '0',
    );
    threshold = TextEditingController(
      text: p?.lowStockThreshold.toString() ?? '5',
    );
  }

  @override
  void dispose() {
    for (final c in [
      name,
      sku,
      category,
      unit,
      description,
      purchase,
      selling,
      threshold,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required field' : null;
  String? _amount(String? value) {
    final n = double.tryParse(value?.trim() ?? '');
    if (n == null || !n.isFinite || n < 0) {
      return 'Enter a valid non-negative amount';
    }
    if ((n * 100 - (n * 100).round()).abs() > 0.000001) {
      return 'Use up to 2 decimal places';
    }
    return null;
  }

  String? _quantity(String? value) {
    final n = double.tryParse(value?.trim() ?? '');
    if (n == null || !n.isFinite || n < 0) {
      return 'Enter a valid quantity';
    }
    if ((n * 1000 - (n * 1000).round()).abs() > 0.000001) {
      return 'Use up to 3 decimal places';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = Get.find<InventoryViewModel>();
    return PremiumEntrance(
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.product == null ? 'Add Product' : 'Edit Product'),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    'Product details',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set accurate product details. Manage stock separately using audited adjustments.',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: name,
                    validator: _required,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sku,
                    decoration: const InputDecoration(
                      labelText: 'SKU (optional)',
                      prefixIcon: Icon(Icons.qr_code),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: category,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: unit,
                          validator: _required,
                          decoration: const InputDecoration(
                            labelText: 'Unit (pcs, kg, etc.)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: purchase,
                          validator: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Purchase price (Rs)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: selling,
                          validator: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Selling price (Rs)',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: threshold,
                    validator: _quantity,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Low-stock alert at quantity',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: description,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(
                    () => FilledButton.icon(
                      onPressed: vm.saving.value
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) {
                                return;
                              }
                              final ok = await vm.save(
                                id: widget.product?.id,
                                name: name.text,
                                category: category.text,
                                unit: unit.text,
                                sku: sku.text,
                                description: description.text,
                                purchasePrice: double.parse(purchase.text),
                                sellingPrice: double.parse(selling.text),
                                lowStockThreshold: double.parse(threshold.text),
                              );
                              if (!mounted) {
                                return;
                              }
                              if (ok) {
                                Get.back();
                                Get.snackbar(
                                  'Saved',
                                  'Product saved successfully.',
                                );
                              } else {
                                Get.snackbar(
                                  'Error',
                                  vm.error.value ?? 'Could not save product',
                                );
                              }
                            },
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        vm.saving.value ? 'Saving...' : 'Save Product',
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
