import 'dart:convert';
import 'package:http/http.dart' as http;

class BackendService {
  // Configured default points to the deployed Render backend service,
  // allowing override using --dart-define=BACKEND_URL during execution.
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://gait-backend-wkp6.onrender.com',
  );

  /// Dispatches structured historical patient trial data to the backend '/generate' endpoint
  /// to obtain AI-assisted patient progression summaries.
  static Future<String> generateOverallInsights({
    required Map<String, dynamic> data,
    required bool isSinglePatient,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'data': data,
        'is_single_patient': isSinglePatient,
      }),
    ).timeout(const Duration(seconds: 90));

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      return decoded['insights'] as String? ?? 'No insights returned from backend.';
    } else {
      throw Exception('Server returned code ${response.statusCode}: ${response.body}');
    }
  }
}
