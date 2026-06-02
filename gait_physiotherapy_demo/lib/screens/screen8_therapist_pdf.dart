import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/session_provider.dart';

class Screen8TherapistPdf extends ConsumerWidget {
  const Screen8TherapistPdf({super.key});

  void _triggerPdfExport(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(sessionProvider.notifier).generatePhysioReport();

    if (!success) {
      final error = ref.read(sessionProvider).errorMessage ?? 'Report generation failed.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFFF4E6A),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(sessionProvider);
    final hasReport = sessionState.pdfPath != null;

    return Scaffold(
      body: Column(
        children: [
          // ── Dark Header ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF1A1D2E),
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
                      onTap: () => Navigator.pop(context),
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
                            Icon(Icons.picture_as_pdf, color: Color(0xFFFF4E6A), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Physiotherapist Report compiler',
                              style: TextStyle(color: Color(0xFF1A1D2E), fontSize: 15, fontWeight: FontWeight.bold),
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

                  if (hasReport) ...[
                    const Text(
                      'Compiled Report Summary',
                      style: TextStyle(
                        color: Color(0xFF1A1D2E),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C48C).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF00C48C).withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.check_circle, color: Color(0xFF00C48C), size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  sessionState.syncStatusMessage,
                                  style: const TextStyle(color: Color(0xFF1A1D2E), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Saved Path: ${sessionState.pdfPath}',
                            style: TextStyle(color: Colors.black.withOpacity(0.4), fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Spacer(),

                  GestureDetector(
                    onTap: sessionState.isGeneratingPdf ? null : () => _triggerPdfExport(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 17),
                      decoration: BoxDecoration(
                        color: hasReport ? const Color(0xFF6C63FF) : const Color(0xFFFF4E6A),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: (hasReport ? const Color(0xFF6C63FF) : const Color(0xFFFF4E6A)).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Center(
                        child: sessionState.isGeneratingPdf
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
