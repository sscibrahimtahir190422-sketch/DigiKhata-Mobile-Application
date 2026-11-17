import 'package:digikhata/core/widgets/premium_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/locale_preferences.dart';
import '../viewmodels/settings_view_model.dart';

class SettingsView extends GetView<SettingsViewModel> {
  const SettingsView({super.key});
  @override
  Widget build(BuildContext context) => PremiumEntrance(
    child: Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: AppTheme.lightGreen,
                        child: Icon(
                          Icons.storefront_outlined,
                          color: AppTheme.primaryGreen,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your shop account',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              controller.currentEmail,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Language',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Card(
                child: RadioGroup<String>(
                  groupValue: Get.locale?.languageCode ?? 'en',
                  onChanged: (language) async {
                    if (language == null) {
                      return;
                    }
                    try {
                      await LocalePreferences.change(
                        Supabase.instance.client,
                        language,
                      );
                    } catch (error) {
                      Get.snackbar('Language update failed', '$error');
                    }
                  },
                  child: const Column(
                    children: [
                      RadioListTile<String>(
                        title: Text('English'),
                        value: 'en',
                      ),
                      Divider(),
                      RadioListTile<String>(title: Text('اردو'), value: 'ur'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  leading: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppTheme.primaryGreen,
                  ),
                  title: const Text('Privacy & security'),
                  subtitle: const Text(
                    'Each shop\'s data is protected by Supabase authentication and row-level security.',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => FilledButton.icon(
                  onPressed: controller.busy.value ? null : controller.signOut,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    controller.busy.value ? 'Signing out...' : 'Sign out',
                  ),
                ),
              ),
              Obx(
                () => controller.error.value == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          controller.error.value!,
                          style: const TextStyle(color: AppTheme.danger),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
