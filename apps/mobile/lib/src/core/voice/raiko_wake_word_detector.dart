class RaikoWakeWordDetector {
  bool _isListening = false;

  /// Initialize Porcupine with access key from picovoice.ai
  Future<void> initialize(String accessKey) async {
    try {
      if (accessKey.isEmpty) {
        throw Exception('Porcupine access key is required');
      }
    } catch (e) {
      throw Exception('Failed to initialize wake word detector: $e');
    }
  }

  /// Start listening for wake word "Raiko"
  /// Note: This is a placeholder that simulates wake word detection.
  /// In production, integrate with porcupine_flutter package.
  Future<void> startListening(
    Function(bool detected) onWakeWordDetected,
  ) async {
    if (_isListening) return;
    _isListening = true;

    try {
      while (_isListening) {
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      throw Exception('Wake word detection error: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
  }

  Future<void> dispose() async {
    await stopListening();
  }
}
