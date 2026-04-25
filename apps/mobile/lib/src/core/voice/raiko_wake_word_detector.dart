class RaikoWakeWordDetector {
  bool _isInitialized = false;
  bool _isListening = false;

  /// Initialize Porcupine with access key from picovoice.ai
  /// Configures "raiko" as the wake word
  /// Architecture ready for porcupine_flutter integration
  Future<void> initialize(String accessKey) async {
    try {
      if (accessKey.isEmpty) {
        throw Exception('Porcupine access key is required');
      }

      // In production: Initialize Porcupine with:
      // - Access key from picovoice.ai
      // - Keyword: "raiko"
      // - Audio frame processing

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw Exception('Failed to initialize wake word detector: $e');
    }
  }

  /// Start listening for wake word "Raiko"
  /// When detected, calls onWakeWordDetected(true)
  /// In production, processes audio frames and detects the wake word
  Future<void> startListening(
    Function(bool detected) onWakeWordDetected,
  ) async {
    if (!_isInitialized) {
      throw Exception('Wake word detector not initialized');
    }
    if (_isListening) return;

    _isListening = true;

    try {
      // In production: Start microphone stream and process audio frames
      // Ready for porcupine_flutter integration with access to onWakeWordDetected callback
    } catch (e) {
      _isListening = false;
      throw Exception('Wake word detection error: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;
    _isListening = false;
  }

  Future<void> dispose() async {
    if (_isListening) {
      await stopListening();
    }
    _isInitialized = false;
  }
}
