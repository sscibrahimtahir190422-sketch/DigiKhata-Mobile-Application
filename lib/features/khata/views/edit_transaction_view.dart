import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../models/khata_transaction.dart';
import '../viewmodels/khata_view_model.dart';

class EditTransactionView extends StatefulWidget {
  const EditTransactionView({super.key});

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final KhataViewModel _controller;
  late final KhataTransaction _transaction;
  late String _selectedType;

  @override
  void initState() {
    super.initState();

    _controller = Get.find<KhataViewModel>();

    final arguments = Get.arguments;
    if (arguments is! Map || arguments['transaction'] is! KhataTransaction) {
      throw ArgumentError(
        'EditTransactionView requires a transaction argument.',
      );
    }

    _transaction = arguments['transaction'] as KhataTransaction;
    _selectedType = _transaction.type;
    _amountController.text = _transaction.amount.toStringAsFixed(2);
    _descriptionController.text = _transaction.description ?? '';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_controller.isSaving.value || !_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || !amount.isFinite || amount <= 0) return;

    final success = await _controller.updateTransaction(
      transactionId: _transaction.id,
      type: _selectedType,
      amount: amount,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Get.back(result: true);
      Get.snackbar(
        'Updated',
        'Transaction updated successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.lightGreen,
        colorText: AppTheme.darkGreen,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value ?? 'Unable to update transaction.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFFFEEEE),
        colorText: AppTheme.danger,
        margin: const EdgeInsets.all(16),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'credit',
                  label: Text('Credit'),
                  icon: Icon(Icons.shopping_bag_outlined),
                ),
                ButtonSegment(
                  value: 'payment',
                  label: Text('Payment'),
                  icon: Icon(Icons.payments_outlined),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (selection) {
                setState(() => _selectedType = selection.first);
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount in PKR',
                prefixText: 'Rs. ',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');
                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter an amount greater than zero.';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'e.g. Grocery items or partial payment',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Obx(
              () => SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _controller.isSaving.value ? null : _save,
                  icon: _controller.isSaving.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _controller.isSaving.value
                        ? 'Saving Changes...'
                        : 'Save Changes',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
