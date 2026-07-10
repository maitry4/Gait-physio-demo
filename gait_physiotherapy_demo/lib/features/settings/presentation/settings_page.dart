import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:gait_physiotherapy_demo/features/home/presentation/widgets/grid_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedSlm = 'online';
  bool _federatedLearningConsent = false;

  @override
  Widget build(BuildContext context) {
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
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: const Text('Online (Default)', style: TextStyle(fontWeight: FontWeight.w600)),
                    value: 'online',
                    groupValue: _selectedSlm,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedSlm = val!),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    title: const Text('Phi-4 Mini (Local)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Min. req: 4GB RAM (8GB+ recommended), ~3GB storage'),
                    value: 'phi-4-mini',
                    groupValue: _selectedSlm,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedSlm = val!),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  RadioListTile<String>(
                    title: const Text('Gemma 4 (Local)', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text('Min. req: ~1.5GB-4GB RAM (E2B) or 6GB-8GB RAM (E4B)'),
                    value: 'gemma-4',
                    groupValue: _selectedSlm,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _selectedSlm = val!),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Privacy & Data',
              style: TextStyle(
                color: AppColors.navy,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Federated Learning Consent', style: TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: const Text("By enabling this, you agree to share your patient's data anonymously."),
                    value: _federatedLearningConsent,
                    activeColor: AppColors.primary,
                    onChanged: (val) => setState(() => _federatedLearningConsent = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
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
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
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
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
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
