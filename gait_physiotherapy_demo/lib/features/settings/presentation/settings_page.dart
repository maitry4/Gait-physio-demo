import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/settings/presentation/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  Future<void> _handleSlmChange(
    BuildContext context,
    WidgetRef ref,
    String currentValue,
    String? newValue,
  ) async {
    if (newValue == null || newValue == currentValue) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change SLM Preference?'),
          content: Text(
            'Are you sure you want to change the SLM preference to $newValue? '
            'Local models may require downloading large files and use more system resources.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      ref.read(settingsProvider.notifier).updateSlmPreference(newValue);
    }
  }

  Future<void> _handleSave(BuildContext context, WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).save();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved')),
    );
  }

  Future<void> _handleImportData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).importData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database imported successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _handleCreateTestData(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(settingsProvider.notifier).createTestData();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test data created successfully')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final hasUnsavedChanges = ref.watch(hasUnsavedSettingsChangesProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SLM Preference',
              style: TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Online (Default)', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: 'online',
                    groupValue: settings.slmPreference,
                    activeColor: AppColors.primary,
                    onChanged: (val) => _handleSlmChange(context, ref, settings.slmPreference, val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    title: const Text('Phi-4 Mini (Local)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Min. req: 4GB RAM (8GB+ recommended), ~3GB storage'),
                    value: 'phi-4-mini',
                    groupValue: settings.slmPreference,
                    activeColor: AppColors.primary,
                    onChanged: (val) => _handleSlmChange(context, ref, settings.slmPreference, val),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    title: const Text('Gemma 4 (Local)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Min. req: ~1.5GB-4GB RAM (E2B) or 6GB-8GB RAM (E4B)'),
                    value: 'gemma-4',
                    groupValue: settings.slmPreference,
                    activeColor: AppColors.primary,
                    onChanged: (val) => _handleSlmChange(context, ref, settings.slmPreference, val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Privacy & Data',
              style: TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Federated Learning Consent', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text("By enabling this, you agree to share your patient's data anonymously."),
                value: settings.federatedLearningConsent,
                activeColor: AppColors.primary,
                onChanged: (val) => ref.read(settingsProvider.notifier).updateConsent(val),
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () => _handleSave(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Settings',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting data...')),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.download, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Export Data',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _handleImportData(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.orange.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Import Data',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _handleCreateTestData(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 17),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(color: Colors.purple.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bug_report, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Create Test Data',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.2),
                      ),
                    ],
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