import 'dart:convert';
import 'dart:io';

import 'voice_models.dart';

class RaikoIntentParser {
  late String _backendUrl;
  late String _authToken;
  late HttpClient _httpClient;

  Future<void> initialize(String backendUrl, String authToken) async {
    try {
      // Upgrade HTTP to HTTPS if server requires it
      _backendUrl = backendUrl.replaceFirst(RegExp(r'^http://'), 'https://');
      _authToken = authToken;
      _httpClient = HttpClient();
    } catch (e) {
      throw Exception('Failed to initialize intent parser: $e');
    }
  }

  Future<RaikoIntent> parse(
    String transcribedText,
    List<String> availableAgents,
    String userName,
  ) async {
    try {
      // Construct URL - ensure proper formatting for resolve()
      final baseUrl = _backendUrl.endsWith('/') ? _backendUrl : '$_backendUrl/';
      final uri = Uri.parse(baseUrl).resolve('api/intent-parse');
      final request = await _httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-raiko-token', _authToken);

      final body = jsonEncode({
        'text': transcribedText,
        'agents': availableAgents,
        'userName': userName,
      });

      request.contentLength = body.length;
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final json = jsonDecode(responseBody) as Map<String, dynamic>;

        return RaikoIntent(
          command: json['command'] ?? 'ask_clarification',
          targetAgent: json['targetAgent'] ?? 'all',
          confidence: (json['confidence'] ?? 0.0).toDouble(),
        );
      } else {
        throw Exception('Intent parsing failed: HTTP ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Intent parsing failed: $e');
    }
  }

  Future<void> dispose() async {
    _httpClient.close();
  }
}
