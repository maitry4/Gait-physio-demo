import 'package:flutter/material.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/features/research_share/presentation/providers/research_share_provider.dart';

class Screen7ResearchShare extends ConsumerWidget {
  const Screen7ResearchShare({super.key});

  void _triggerShare(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(researchShareProvider.notifier);
    final success = await notifier.shareAnonymousDataset();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dataset successfully anonymized and sent to cloud gait depository!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final error = ref.read(researchShareProvider).errorMessage ?? 'Sharing failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shareState = ref.watch(researchShareProvider);

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(36),
                bottomRight: Radius.circular(36),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Research Registry',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Research Info & Trigger ──────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: AppColors.success, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'GDPR Anonymization Core',
                              style: TextStyle(color: AppColors.navy, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Before transmission to the cloud research dataset, the local engine strips all names, dates of birth, and clinician notes. Only raw biomechanical parameters (cadence, stride length, stance metrics, waveforms) are exported.',
                          style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Anonymization Summary logs',
                    style: TextStyle(
                      color: AppColors.navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(Icons.account_box, 'Stripped Patient Identifiers:', 'YES'),
                  _buildSummaryRow(Icons.note_alt, 'Stripped Patient Medical History:', 'YES'),
                  _buildSummaryRow(Icons.fingerprint, 'Randomized Unique Participant UUIDs:', 'YES'),
                  _buildSummaryRow(Icons.cloud_upload_outlined, 'Transfer Protocol Encryption:', 'AES-256 HTTPS'),

                  const Spacer(),

                  GestureDetector(
                    onTap: shareState.isSharingDataset ? null : () => _triggerShare(context, ref),
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
                      child: Center(
                        child: shareState.isSharingDataset
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share, color: Colors.white, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Anonymize & Upload Dataset',
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
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 18),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: Colors.black.withOpacity(0.6), fontSize: 13)),
          const Spacer(),
          Text(status, style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}
