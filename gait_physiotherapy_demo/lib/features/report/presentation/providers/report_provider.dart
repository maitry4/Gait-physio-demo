import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gait_physiotherapy_demo/core/services/sqlite_service.dart';
import 'package:gait_physiotherapy_demo/core/services/pdf_service.dart';
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class ReportState {
  final bool isGeneratingPdf;
  final String? pdfPath;
  final String syncStatusMessage;
  final String? errorMessage;
  final String? selectedPatientId;

  ReportState({
    this.isGeneratingPdf = false,
    this.pdfPath,
    this.syncStatusMessage = '',
    this.errorMessage,
    this.selectedPatientId,
  });

  ReportState copyWith({
    bool? isGeneratingPdf,
    String? Function()? pdfPath,
    String? syncStatusMessage,
    String? Function()? errorMessage,
    String? Function()? selectedPatientId,
  }) {
    return ReportState(
      isGeneratingPdf: isGeneratingPdf ?? this.isGeneratingPdf,
      pdfPath: pdfPath != null ? pdfPath() : this.pdfPath,
      syncStatusMessage: syncStatusMessage ?? this.syncStatusMessage,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      selectedPatientId: selectedPatientId != null ? selectedPatientId() : this.selectedPatientId,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() {
    return ReportState();
  }

  void selectPatient(String patientId) {
    state = state.copyWith(
      selectedPatientId: () => patientId,
      pdfPath: () => null, // Reset generated report path when patient changes
      syncStatusMessage: '',
      errorMessage: () => null,
    );
  }

  // ── Generate Clinician PDF Success Report ──────────────────────────────
  Future<bool> generatePhysioReport() async {
    final patientId = state.selectedPatientId;
    if (patientId == null) {
      state = state.copyWith(
        isGeneratingPdf: false,
        errorMessage: () => 'Please select a patient first.',
      );
      return false;
    }

    state = state.copyWith(isGeneratingPdf: true, errorMessage: () => null);

    try {
      final db = await SQLiteService.database;

      // 1. Fetch patient details from SQLiteService
      final List<Map<String, dynamic>> patientResults = await db.query(
        'patients',
        where: 'id = ?',
        whereArgs: [patientId],
      );

      if (patientResults.isEmpty) {
        state = state.copyWith(
          isGeneratingPdf: false,
          errorMessage: () => 'Patient profile not found in local SQLite database.',
        );
        return false;
      }

      final patientMap = patientResults.first;
      final patient = UserModel(
        id: patientMap['id'] as String,
        name: patientMap['name'] as String,
        age: patientMap['age'] as int,
        dateAdded: patientMap['created_at'] as String,
      );

      // 2. Fetch session rows from SQLiteService
      final List<Map<String, dynamic>> sessionsList = await db.query(
        'sessions',
        where: 'patient_id = ?',
        whereArgs: [patientId],
        orderBy: 'date DESC',
      );

      if (sessionsList.isEmpty) {
        state = state.copyWith(
          isGeneratingPdf: false,
          errorMessage: () => 'No session records found for ${patient.name} to compile report.',
        );
        return false;
      }

      // 3. Fetch patient insights aggregates
      final insights = await SQLiteService.getPatientInsights(patientId);

      // 4. Fetch cached AI summary
      final String? overallInsights = patientMap['overall_insights'] as String?;

      // 5. Generate real PDF and save it locally
      final savedPath = await PdfService.generateClinicianReport(
        patient: patient,
        insights: insights,
        sessionsList: sessionsList,
        overallInsights: overallInsights,
      );

      final avgSymmetry = (insights['symmetry'] as double).toStringAsFixed(1);
      final avgScore = (insights['avg_score'] as double).toStringAsFixed(1);
      final avgCadence = (insights['avg_cadence'] as double).toStringAsFixed(0);

      state = state.copyWith(
        isGeneratingPdf: false,
        pdfPath: () => savedPath,
        syncStatusMessage: 'Clinical Report PDF successfully compiled! Average Symmetry: $avgSymmetry%, Avg Score: $avgScore, Avg Cadence: $avgCadence spm over ${sessionsList.length} sessions.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isGeneratingPdf: false,
        errorMessage: () => 'PDF compilation error: $e',
      );
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
