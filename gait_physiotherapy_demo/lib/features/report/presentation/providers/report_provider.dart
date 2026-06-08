import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/database/database_service.dart';

class ReportState {
  final bool isGeneratingPdf;
  final String? pdfPath;
  final String syncStatusMessage;
  final String? errorMessage;

  ReportState({
    this.isGeneratingPdf = false,
    this.pdfPath,
    this.syncStatusMessage = '',
    this.errorMessage,
  });

  ReportState copyWith({
    bool? isGeneratingPdf,
    String? Function()? pdfPath,
    String? syncStatusMessage,
    String? Function()? errorMessage,
  }) {
    return ReportState(
      isGeneratingPdf: isGeneratingPdf ?? this.isGeneratingPdf,
      pdfPath: pdfPath != null ? pdfPath() : this.pdfPath,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    return ReportState();
  }

  // ── Generate Clinician PDF Success Report ──────────────────────────────
  Future<bool> generatePhysioReport() async {
    state = state.copyWith(isGeneratingPdf: true, errorMessage: () => null);

    try {
      final sessions = await DatabaseService.instance.getAllSessions();
      if (sessions.isEmpty) {
        state = state.copyWith(isGeneratingPdf: false, errorMessage: () => 'No sessions found in database to compile report.');
        return false;
      }

      await Future.delayed(const Duration(seconds: 2));

      double totalSymmetry = 0;
      double totalScore = 0;
      int totalCadence = 0;
      for (var s in sessions) {
        totalSymmetry += s.symmetry;
        totalScore += s.score;
        totalCadence += s.cadence;
      }
      final avgSymmetry = (totalSymmetry / sessions.length).toStringAsFixed(1);
      final avgScore = (totalScore / sessions.length).toStringAsFixed(1);
      final avgCadence = (totalCadence / sessions.length).toStringAsFixed(0);

      state = state.copyWith(
        isGeneratingPdf: false,
        pdfPath: () => '/storage/emulated/0/GaitPhysio/Reports/Therapist_Summary_${DateTime.now().millisecondsSinceEpoch}.pdf',
        syncStatusMessage: 'Physio Success Report PDF ready! Average Symmetry: $avgSymmetry%, Avg Score: $avgScore, Avg Cadence: $avgCadence spm over ${sessions.length} sessions.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isGeneratingPdf: false, errorMessage: () => 'PDF compilation error: $e');
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: () => null);
  }
}

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(() {
  return ReportNotifier();
});
