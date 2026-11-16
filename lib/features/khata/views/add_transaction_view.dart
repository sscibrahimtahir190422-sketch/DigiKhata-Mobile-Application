import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/khata_view_model.dart';

class AddTransactionView extends StatefulWidget {
  const AddTransactionView({super.key});

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final KhataViewModel _controller;
  late final String _customerName;
  final _selectedType = 'credit'.obs;

  @override
  void initState() {
    super.initState();

    _controller = Get.find<KhataViewModel>();

    final arguments = Get.arguments as Map?;
    _customerName = arguments?['customerName'] as String? ?? 'Customer';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _selectedType.close();
    super.dispose();
  }

  Future<void> _saveTransaction() async {
    if (_controller.isLoading.value) return;

    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || !amount.isFinite || amount <= 0) {
      return;
    }

    final success = await _controller.addTransaction(
      type: _selectedType.value,
      amount: amount,
      description: _descriptionController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      Get.back();

      Get.snackbar(
        'Success',
        'Transaction saved successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppTheme.lightGreen,
        colorText: AppTheme.darkGreen,
        margin: const EdgeInsets.all(16),
      );
    } else {
      Get.snackbar(
        'Error',
        _controller.errorMessage.value ?? 'Unable to save transaction.',
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
      appBar: AppBar(title: const Text('Add Khata Entry')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Customer information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.lightGreen,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_outline_rounded,
                      color: AppTheme.primaryGreen,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CUSTOMER',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _customerName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.darkGreen,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.verified_user_outlined,
                    color: AppTheme.primaryGreen,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Transaction Type',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose the type of entry you want to record.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 14),

            Obx(() {
              final isCredit = _selectedType.value == 'credit';

              return Row(
                children: [
                  Expanded(
                    child: _TransactionTypeCard(
                      title: 'Credit Given',
                      subtitle: 'Customer owes you',
                      icon: Icons.shopping_bag_outlined,
                      color: AppTheme.danger,
                      background: const Color(0xFFFFEEEE),
                      selected: isCredit,
                      onTap: () => _selectedType.value = 'credit',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TransactionTypeCard(
                      title: 'Payment',
                      subtitle: 'Money received',
                      icon: Icons.payments_outlined,
                      color: AppTheme.success,
                      background: AppTheme.lightGreen,
                      selected: !isCredit,
                      onTap: () => _selectedType.value = 'payment',
                    ),
                  ),
                ],
              );
            }),

            const SizedBox(height: 28),

            const Text(
              'Transaction Amount',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
              decoration: const InputDecoration(
                labelText: 'Amount in PKR',
                hintText: '0.00',
                prefixText: 'Rs. ',
                prefixIcon: Icon(
                  Icons.currency_exchange_rounded,
                  color: AppTheme.primaryGreen,
                ),
              ),
              validator: (value) {
                final amount = double.tryParse(value?.trim() ?? '');

                if (amount == null || !amount.isFinite || amount <= 0) {
                  return 'Enter an amount greater than zero.';
                }

                return null;
              },
            ),

            const SizedBox(height: 24),

            const Text(
              'Description',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a note to help identify this transaction.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'e.g. Grocery items or partial payment',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 44),
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Obx(
              () => SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _controller.isLoading.value
                      ? null
                      : _saveTransaction,
                  icon: _controller.isLoading.value
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
                    _controller.isLoading.value
                        ? 'Saving Transaction...'
                        : 'Save Transaction',
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AppTheme.textSecondary,
                ),
                SizedBox(width: 6),
                Text(
                  'Check the amount before saving.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionTypeCard extends StatelessWidget {
  const _TransactionTypeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.background,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color background;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? background : AppTheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? color : const Color(0xFFE8EFEB),
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 25),
                  const Spacer(),
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: selected ? color : AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
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
  }
}
