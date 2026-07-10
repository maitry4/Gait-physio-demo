import 'dart:io';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:gait_physiotherapy_demo/core/themes/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gait_physiotherapy_demo/features/report/presentation/providers/report_provider.dart';
import 'package:gait_physiotherapy_demo/features/user_management/presentation/providers/user_provider.dart';

class Screen8TherapistPdf extends ConsumerWidget {
  const Screen8TherapistPdf({super.key});

  void _triggerPdfExport(BuildContext context, WidgetRef ref) async {
    final reportState = ref.read(reportProvider);

    if (reportState.pdfPath != null) {
      // PDF is already compiled! Let's print/share it.
      final file = File(reportState.pdfPath!);
      if (await file.exists()) {
        final pdfBytes = await file.readAsBytes();
        await Printing.layoutPdf(
          onLayout: (format) => pdfBytes,
          name: 'Gait_Physio_Report_${DateTime.now().millisecondsSinceEpoch}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved PDF file not found. Recompiling report...'),
            backgroundColor: AppColors.primary,
          ),
        );
        await ref.read(reportProvider.notifier).generatePhysioReport();
      }
      return;
    }

    final success = await ref.read(reportProvider.notifier).generatePhysioReport();

    if (!success) {
      final error = ref.read(reportProvider).errorMessage ?? 'Report generation failed.';
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
    final reportState = ref.watch(reportProvider);
    final hasReport = reportState.pdfPath != null;
    final users = ref.watch(userProvider).users;
    final selectedPatientId = reportState.selectedPatientId;

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
                      'Report Exporter',
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

          // ── Exporter details ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Patient Selector
                  if (users.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: const Text(
                        'No patients found in local SQLite database. Please go to Settings to seed test data or Add New User first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.navy, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    )
                  else ...[
                    const Text(
                      'Select Patient Profile',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedPatientId,
                          hint: const Row(
                            children: [
                              Icon(Icons.person_outline, size: 20, color: Colors.grey),
                              SizedBox(width: 8),
                              Text('Choose a patient to report...', style: TextStyle(color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navy),
                          items: users.map((user) {
                            return DropdownMenuItem<String>(
                              value: user.id,
                              child: Row(
                                children: [
                                  const Icon(Icons.person_outline, size: 20, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${user.name} (Age ${user.age})',
                                    style: const TextStyle(
                                      color: AppColors.navy,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (patientId) {
                            if (patientId != null) {
                              ref.read(reportProvider.notifier).selectPatient(patientId);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // 2. Info Box
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
                            Icon(Icons.picture_as_pdf, color: AppColors.primary, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Physiotherapist Report Compiler',
                              style: TextStyle(color: AppColors.navy, fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Generates a comprehensive diagnostic audit detailing rehabilitation progression trends, average cadence scores, and patient central tendencies extracted across all active local SQLite databases.',
                          style: TextStyle(color: Colors.black.withOpacity(0.55), fontSize: 13, height: 1.5),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Compiled summary details card
                  if (hasReport) ...[
                    const Text(
                      'Compiled Report Summary',
                      style: TextStyle(
                        color: AppColors.navy,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Gait Assessment Report',
                                      style: TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      reportState.pdfPath!.split('/').last,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.black.withOpacity(0.4),
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Ready',
                                  style: TextStyle(
                                    color: AppColors.success,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  reportState.syncStatusMessage,
                                  style: TextStyle(
                                    color: AppColors.navy.withOpacity(0.7),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  GestureDetector(
                    onTap: reportState.isGeneratingPdf || (users.isEmpty) ? null : () => _triggerPdfExport(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: users.isEmpty
                            ? Colors.grey.shade400
                            : (hasReport ? AppColors.secondary : AppColors.primary),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          if (users.isNotEmpty)
                            BoxShadow(
                              color: (hasReport ? AppColors.secondary : AppColors.primary).withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                        ],
                      ),
                      child: Center(
                        child: reportState.isGeneratingPdf
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(hasReport ? Icons.print_outlined : Icons.picture_as_pdf, color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    hasReport ? 'Print & Export Report' : 'Compile PDF Report',
                                    style: const TextStyle(
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
}
