import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_theme.dart';
import '../viewmodels/customer_view_model.dart';

class AddCustomerView extends GetView<CustomerViewModel> {
  const AddCustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Add Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.darkGreen, AppTheme.primaryGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.person_add_alt_1_rounded,
                      color: Colors.white,
                      size: 34,
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Build your customer list',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Save customer details to manage their '
                      'khata and track payments easily.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.5,
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
              const SizedBox(height: 6),
              const Text(
                'Enter the details below to create a customer record.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 22),

              // Customer name
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
                  hintText: 'e.g. Ahmed Khan',
                  prefixIcon: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  counterText: '',
                ),
                validator: (value) {
                  final name = value?.trim() ?? '';

                  if (name.isEmpty) {
                    return 'Please enter the customer name.';
                  }

                  if (name.length < 2) {
                    return 'Name must contain at least 2 characters.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Phone number
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
                    return 'Please enter a phone number.';
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

              // Save button
              Obx(
                () => ElevatedButton.icon(
                  onPressed: controller.isLoading.value
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          final added = await controller.addCustomer(
                            name: nameController.text.trim(),
                            phone: phoneController.text.trim(),
                          );

                          if (added) {
                            Get.back();

                            Get.snackbar(
                              'Success',
                              'Customer added successfully.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: AppTheme.lightGreen,
                              colorText: AppTheme.darkGreen,
                              margin: const EdgeInsets.all(16),
                            );
                          } else {
                            Get.snackbar(
                              'Unable to add customer',
                              controller.errorMessage.value ??
                                  'Please try again.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFFFFEEEE),
                              colorText: AppTheme.danger,
                              margin: const EdgeInsets.all(16),
                            );
                          }
                        },
                  icon: controller.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_rounded),
                  label: Text(
                    controller.isLoading.value
                        ? 'Saving Customer...'
                        : 'Save Customer',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 17,
                    color: AppTheme.textSecondary,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'Customer records are saved to your database.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
