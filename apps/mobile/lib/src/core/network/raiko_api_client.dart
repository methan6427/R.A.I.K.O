import 'dart:convert';
import 'dart:io';

import '../config/raiko_backend_config.dart';
import 'raiko_backend_models.dart';

class RaikoApiClient {
  RaikoApiClient({required RaikoBackendConfig config}) : _config = config;

  RaikoBackendConfig _config;

  void updateConfig(RaikoBackendConfig nextConfig) {
    _config = nextConfig;
  }

  Future<RaikoOverviewSnapshot> fetchOverview() async {
    final json = await _getJson('/api/overview');
    return RaikoOverviewSnapshot.fromJson(json);
  }

  Future<List<RaikoDeviceInfo>> fetchDevices() async {
    final json = await _getJson('/api/devices');
    return _decodeDevices(json['devices']);
  }

  Future<List<RaikoAgentInfo>> fetchAgents() async {
    final json = await _getJson('/api/agents');
    return _decodeAgents(json['agents']);
  }

  Future<List<RaikoActivityInfo>> fetchActivity() async {
    final json = await _getJson('/api/activity');
    return _decodeActivity(json['activity']);
  }

  Future<List<RaikoCommandInfo>> fetchCommands() async {
    final json = await _getJson('/api/commands');
    return _decodeCommands(json['commands']);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final client = HttpClient();

    try {
      final request = await client.getUrl(_resolve(path));
      _applyRequestHeaders(request);
      final response = await request.close();
      return _readJson(response, path);
    } finally {
      client.close(force: true);
    }
  }

  Future<Map<String, dynamic>> _readJson(
    HttpClientResponse response,
    String path,
  ) async {
    final responseBody = await response.transform(utf8.decoder).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        _decodeErrorMessage(responseBody) ??
            'Request to $path failed with status ${response.statusCode}.',
        uri: _resolve(path),
      );
    }

    if (responseBody.isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(responseBody);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.cast<String, dynamic>();
    }

    throw FormatException('Expected a JSON object from $path.');
  }

  void _applyRequestHeaders(HttpClientRequest request) {
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');

    final token = _config.authToken.trim();
    if (token.isNotEmpty) {
      request.headers.set('x-raiko-token', token);
    }
  }

  Uri _resolve(String path) {
    return Uri.parse(_config.baseHttpUrl).resolve(path);
  }

  String? _decodeErrorMessage(String responseBody) {
    if (responseBody.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic>) {
        return decoded['error'] as String? ?? decoded['message'] as String?;
      }
      if (decoded is Map) {
        final json = decoded.cast<String, dynamic>();
        return json['error'] as String? ?? json['message'] as String?;
      }
    } on FormatException {
      return responseBody;
    }

    return null;
  }

  List<RaikoDeviceInfo> _decodeDevices(dynamic source) {
    final json = <String, dynamic>{'devices': source};
    return RaikoOverviewSnapshot.fromJson(json).devices;
  }

  List<RaikoAgentInfo> _decodeAgents(dynamic source) {
    final json = <String, dynamic>{'agents': source};
    return RaikoOverviewSnapshot.fromJson(json).agents;
  }

  List<RaikoActivityInfo> _decodeActivity(dynamic source) {
    final json = <String, dynamic>{'activity': source};
    return RaikoOverviewSnapshot.fromJson(json).activity;
  }

  List<RaikoCommandInfo> _decodeCommands(dynamic source) {
    final json = <String, dynamic>{'commands': source};
    return RaikoOverviewSnapshot.fromJson(json).commands;
  }
}
