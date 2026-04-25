import 'package:url_launcher/url_launcher.dart';

class AnyDeskIntegration {
  static const String _anyDeskScheme = 'anydesk';

  /// Launch AnyDesk for remote desktop access
  /// Can optionally specify a target session ID
  Future<bool> launch({String? sessionId}) async {
    try {
      final Uri uri = _buildAnyDeskUri(sessionId);

      if (await canLaunchUrl(uri)) {
        return await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
      } else {
        throw Exception('Cannot launch AnyDesk. Is it installed?');
      }
    } catch (e) {
      throw Exception('Failed to launch AnyDesk: $e');
    }
  }

  /// Build AnyDesk URI for unattended access
  /// If sessionId is provided, connect directly to that session
  Uri _buildAnyDeskUri(String? sessionId) {
    if (sessionId != null && sessionId.isNotEmpty) {
      return Uri(
        scheme: _anyDeskScheme,
        host: 'connect',
        queryParameters: {'alias': sessionId},
      );
    }

    // Open AnyDesk main application
    return Uri(scheme: _anyDeskScheme);
  }

  /// Check if AnyDesk is installed on the device
  Future<bool> isInstalled() async {
    try {
      final Uri testUri = Uri(scheme: _anyDeskScheme);
      return await canLaunchUrl(testUri);
    } catch (e) {
      return false;
    }
  }
}
