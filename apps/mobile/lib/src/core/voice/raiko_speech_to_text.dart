import 'dart:async';

import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class RaikoSpeechToText {
  late final SpeechToText _speechToText;
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentTranscription = '';

  RaikoSpeechToText() {
    _speechToText = SpeechToText();
  }

  /// Initialize the speech-to-text engine
  /// Must be called before using transcribe()
  Future<void> initialize() async {
    try {
      if (_isInitialized) return;

      final available = await _speechToText.initialize(
        onError: (error) {
          throw Exception('STT Error: ${error.errorMsg}');
        },
        onStatus: (status) {
          // Status updates: listening, notListening, done, etc.
        },
      );

      if (!available) {
        throw Exception('Speech-to-text not available on this device');
      }

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
      throw Exception('Failed to initialize STT: $e');
    }
  }

  /// Record and transcribe audio using device microphone
  /// Returns transcribed text from speech
  Future<String> transcribe({
    Duration recordingDuration = const Duration(seconds: 10),
  }) async {
    try {
      if (!_isInitialized) {
        throw Exception('STT not initialized. Call initialize() first.');
      }

      if (_isListening) {
        throw Exception('Already listening for speech');
      }

      _isListening = true;
      _currentTranscription = '';

      // Listen for speech with device microphone
      await _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          _currentTranscription = result.recognizedWords;
        },
        listenFor: recordingDuration,
        pauseFor: const Duration(seconds: 3),
        localeId: 'en_US',
      );

      // Wait for listening to complete
      await Future.delayed(recordingDuration + const Duration(seconds: 1));

      _isListening = false;
      final result = _currentTranscription;
      _currentTranscription = '';

      return result;
    } catch (e) {
      _isListening = false;
      _currentTranscription = '';
      throw Exception('Transcription failed: $e');
    }
  }

  /// Stop listening immediately
  Future<void> stop() async {
    if (_isListening) {
      await _speechToText.stop();
      _isListening = false;
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }

  bool get isInitialized => _isInitialized;
  bool get isListening => _isListening;
}
