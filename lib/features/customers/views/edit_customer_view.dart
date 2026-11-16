import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../models/customer.dart';
import '../viewmodels/customer_view_model.dart';

class EditCustomerView extends GetView<CustomerViewModel> {
  const EditCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    final customer = Get.arguments as Customer;
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Customer')),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Customer profile header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withValues(alpha: 0.18),
                    child: Text(
                      customer.name.trim().isEmpty
                          ? '?'
                          : customer.name.trim()[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Update customer details',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Editing ${customer.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Customer Information',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Make the necessary changes below.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),

            const SizedBox(height: 22),

            const Text(
              'Full Name',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              maxLength: 100,
              decoration: const InputDecoration(
                hintText: 'Enter customer name',
                prefixIcon: Icon(
                  Icons.person_outline_rounded,
                  color: AppTheme.primaryGreen,
                ),
                counterText: '',
              ),
              validator: (value) {
                final name = value?.trim() ?? '';

                if (name.isEmpty) {
                  return 'Please enter customer name.';
                }

                if (name.length < 2) {
                  return 'Name must contain at least 2 characters.';
                }

                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              'Phone Number',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 9),
            TextFormField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              maxLength: 20,
              decoration: const InputDecoration(
                hintText: 'e.g. 03XXXXXXXXX',
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: AppTheme.primaryGreen,
                ),
                counterText: '',
              ),
              validator: (value) {
                final phone = value?.trim() ?? '';

                if (phone.isEmpty) {
                  return 'Please enter phone number.';
                }

                if (phone.length < 7 ||
                    phone.length > 20 ||
                    !RegExp(r'^[0-9+\-()\s]+$').hasMatch(phone)) {
                  return 'Enter a valid phone number.';
                }

                return null;
              },
            ),

            const SizedBox(height: 30),

            Obx(
              () => ElevatedButton.icon(
                onPressed: controller.isLoading.value
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }

                        final success = await controller.updateCustomer(
                          id: customer.id,
                          name: nameController.text.trim(),
                          phone: phoneController.text.trim(),
                        );

                        if (success) {
                          Get.back();

                          Get.snackbar(
                            'Success',
                            'Customer updated successfully.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: AppTheme.lightGreen,
                            colorText: AppTheme.darkGreen,
                            margin: const EdgeInsets.all(16),
                          );
                        } else {
                          Get.snackbar(
                            'Error',
                            controller.errorMessage.value ??
                                'Unable to update customer.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFFFFEEEE),
                            colorText: AppTheme.danger,
                            margin: const EdgeInsets.all(16),
                          );
                        }
                      },
                icon: controller.isLoading.value
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  controller.isLoading.value
                      ? 'Saving Changes...'
                      : 'Save Changes',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
