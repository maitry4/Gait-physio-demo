import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:gait_physiotherapy_demo/features/user_management/domain/entities/user_entity.dart';

class PdfService {
  static Future<String> generateClinicianReport({
    required UserModel patient,
    required Map<String, dynamic> insights,
    required List<Map<String, dynamic>> sessionsList,
    String? overallInsights,
  }) async {
    final pdf = pw.Document();

    final totalSessions = insights['total_sessions'] as int? ?? 0;
    final avgCadence = insights['avg_cadence'] as double? ?? 0.0;
    final avgGaitSpeed = insights['avg_gait_speed'] as double? ?? 0.0;
    final avgStepTime = insights['avg_step_time'] as double? ?? 0.0;
    final avgStrideLength = insights['avg_stride_length'] as double? ?? 0.0;
    final avgStancePct = insights['avg_stance_pct'] as double? ?? 0.0;
    final avgSwingPct = insights['avg_swing_pct'] as double? ?? 0.0;
    final avgScore = insights['avg_score'] as double? ?? 0.0;
    final symmetry = insights['symmetry'] as double? ?? 100.0;

    String slmSummary = '';
    if (totalSessions == 0) {
      slmSummary = 'No sessions recorded yet to compute dynamic gait cycle recommendations.';
    } else if (symmetry >= 92) {
      slmSummary = 'SLM analysis confirms excellent rehabilitation progress. High gait symmetry score of ${symmetry.toStringAsFixed(1)}% indicates healthy recovery and symmetrical joint loading.';
    } else if (symmetry >= 82) {
      slmSummary = 'SLM analysis: Moderate gait deviation detected. Left-Right stance phase asymmetry indicates mild compensation. Recommend focusing on unilateral strength and weight transfer.';
    } else {
      slmSummary = 'SLM warning: Critical gait asymmetry trend. High joint wear hazard due to asymmetrical stance phases. Review orthotics or brace adjustment immediately.';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (pw.Context context) {
          return [
            // Title Header
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CLINICAL GAIT ANALYSIS REPORT',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.indigo900,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Gait Physio System - Rehabilitation Assessment',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'Report Date: ${DateTime.now().toIso8601String().substring(0, 10)}',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 16),

            // Patient Metadata Section
            pw.Text(
              'Patient Information',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 6),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Name: ${patient.name}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                    pw.Text('Patient ID: ${patient.id}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Age: ${patient.age} years old', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                    pw.Text('Total Trials: $totalSessions sessions logged', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Overall Progression Metrics Grid (Central Tendency)
            pw.Text(
              'Clinical Progression Averages',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 8),

            pw.Column(
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: _buildPdfStatCard('Gait Symmetry', '${symmetry.toStringAsFixed(1)}%')),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _buildPdfStatCard('Mean Cadence', '${avgCadence.toStringAsFixed(0)} spm')),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _buildPdfStatCard('Mean Stride Len', '${avgStrideLength.toStringAsFixed(2)} m')),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: _buildPdfStatCard('Mean Gait Speed', '${avgGaitSpeed.toStringAsFixed(2)} m/s')),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _buildPdfStatCard('Mean Step Time', '${avgStepTime.toStringAsFixed(2)} s')),
                    pw.SizedBox(width: 8),
                    pw.Expanded(child: _buildPdfStatCard('Clinical Score', avgScore.toStringAsFixed(1))),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // Gait Cycle Breakdown
            pw.Text(
              'Gait Cycle Phase Distribution',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Expanded(
                  flex: (avgStancePct * 100).round().clamp(1, 9900),
                  child: pw.Container(
                    height: 14,
                    color: PdfColors.indigo800,
                    child: pw.Center(
                      child: pw.Text('Stance Phase (${avgStancePct.toStringAsFixed(1)}%)', style:  pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                ),
                pw.Expanded(
                  flex: (avgSwingPct * 100).round().clamp(1, 9900),
                  child: pw.Container(
                    height: 14,
                    color: PdfColors.purple800,
                    child: pw.Center(
                      child: pw.Text('Swing Phase (${avgSwingPct.toStringAsFixed(1)}%)', style:  pw.TextStyle(color: PdfColors.white, fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // SLM progression insights
            pw.Text(
              'Clinical Small Language Model (SLM) Diagnostics',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 8),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                slmSummary,
                style: pw.TextStyle(
                  fontSize: 9.5,
                  height: 1.3,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ),
            pw.SizedBox(height: 20),

            // Session History Table
            pw.Text(
              'Historical Session Log Audit',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Session ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Leg', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Cadence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Gait Speed', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Stance %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Swing %', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
                  ],
                ),
                ...sessionsList.map((s) {
                  final avgCad = (s['avg_cadence'] as num?)?.toStringAsFixed(1) ?? '0.0';
                  final avgSpd = (s['avg_gait_speed'] as num?)?.toStringAsFixed(2) ?? '0.00';
                  final stance = (s['stance_pct'] as num?)?.toStringAsFixed(1) ?? '0.0';
                  final swing = (s['swing_pct'] as num?)?.toStringAsFixed(1) ?? '0.0';
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s['id'] as String? ?? 'N/A', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s['date'] as String? ?? 'N/A', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(s['leg'] as String? ?? 'N/A', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$avgCad spm', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$avgSpd m/s', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$stance%', style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('$swing%', style: const pw.TextStyle(fontSize: 8))),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 20),

            // AI Therapist Summary Placeholder
            pw.Text(
              'AI-Generated Therapist Progression Summary',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.indigo900,
              ),
            ),
            pw.Divider(color: PdfColors.indigo900, height: 4),
            pw.SizedBox(height: 8),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(10),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
              ),
              child: pw.Text(
                overallInsights ?? 'No AI progression summary has been generated for this patient yet. Please generate a summary on the Aggregate Analysis screen to include it in this report.',
                style: const pw.TextStyle(
                  fontSize: 8.5,
                  color: PdfColors.grey900,
                  lineSpacing: 1.25,
                ),
              ),
            ),
          ];
        },
      ),
    );

    // Save to local Documents directory
    final outputDir = await getApplicationDocumentsDirectory();
    final reportsFolder = Directory('${outputDir.path}/GaitPhysio/Reports');
    if (!await reportsFolder.exists()) {
      await reportsFolder.create(recursive: true);
    }

    final sanitizedPatientName = patient.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final filePath = '${reportsFolder.path}/Therapist_Summary_${sanitizedPatientName}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    return filePath;
  }

  static pw.Widget _buildPdfStatCard(String label, String value) {
    return pw.Container(
      height: 38,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo900,
            ),
          ),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }
}
