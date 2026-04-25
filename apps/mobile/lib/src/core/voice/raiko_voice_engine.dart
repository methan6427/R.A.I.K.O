import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import '../network/raiko_ws_client.dart';
import '../settings/raiko_settings_store.dart';
import 'raiko_intent_parser.dart';
import 'raiko_speech_to_text.dart';
import 'raiko_wake_word_detector.dart';
import 'voice_models.dart';

class RaikoVoiceEngine extends ChangeNotifier {
  final RaikoWsClient client;
  final RaikoSettingsStore settings;

  late RaikoWakeWordDetector _wakeWordDetector;
  late RaikoSpeechToText _stt;
  late RaikoIntentParser _intentParser;
  late AudioPlayer _audioPlayer;

  RaikoVoiceState _state = RaikoVoiceState.idle;
  String? _lastError;
  bool _initialized = false;

  RaikoVoiceEngine({
    required this.client,
    required this.settings,
  });

  RaikoVoiceState get state => _state;
  String? get lastError => _lastError;
  bool get isInitialized => _initialized;

  Future<void> initialize({
    required String porcupineAccessKey,
    required String geminiApiKey,
  }) async {
    try {
      _wakeWordDetector = RaikoWakeWordDetector();
      _stt = RaikoSpeechToText();
      _intentParser = RaikoIntentParser();
      _audioPlayer = AudioPlayer();

      await _wakeWordDetector.initialize(porcupineAccessKey);
      await _stt.initialize();
      await _intentParser.initialize(geminiApiKey);

      _initialized = true;
      _state = RaikoVoiceState.idle;
      _lastError = null;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _state = RaikoVoiceState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Activate voice assistant (manual tap or wake word detected)
  Future<void> activate() async {
    if (!_initialized) {
      _setError('Voice engine not initialized');
      return;
    }

    try {
      _setState(RaikoVoiceState.listening);

      // Record audio
      final transcribedText = await _stt.transcribe();
      if (transcribedText.isEmpty) {
        _setError('No audio detected');
        return;
      }

      _setState(RaikoVoiceState.processing);

      // Parse intent
      final intent = await _intentParser.parse(
        transcribedText,
        client.agents.map((a) => a.name).toList(),
        client.deviceName,
      );

      // Handle special commands
      if (intent.command == 'set_name') {
        await settings.saveDeviceName(intent.targetAgent);
        _playResponse('Name updated to ${intent.targetAgent}');
        _setState(RaikoVoiceState.idle);
        return;
      }

      if (intent.command == 'ask_clarification') {
        _playResponse('Could you please repeat that? I didn\'t quite understand.');
        _setState(RaikoVoiceState.idle);
        return;
      }

      // Find target agent
      final targetAgents = intent.targetAgent == 'all'
          ? client.agents
          : client.agents
              .where((a) => a.name.toLowerCase().contains(intent.targetAgent.toLowerCase()))
              .toList();

      if (targetAgents.isEmpty) {
        _playResponse('I couldn\'t find ${intent.targetAgent}. Which agent did you mean?');
        _setState(RaikoVoiceState.idle);
        return;
      }

      // Check if confirmation is needed
      final confirmBeforeExecute = settings.confirmBeforeExecute ?? true;
      if (confirmBeforeExecute) {
        _setState(RaikoVoiceState.confirming);
        final confirmMessage = _buildConfirmationMessage(
          intent.command,
          targetAgents.map((a) => a.name).toList(),
          client.deviceName,
        );
        _playResponse(confirmMessage);
        // TODO: Wait for user confirmation before executing
      }

      // Execute command
      _setState(RaikoVoiceState.executing);
      // Send command to the first matching agent (client has it pre-selected)
      client.sendCommand(intent.command);

      _setState(RaikoVoiceState.speaking);
      final successMessage = _buildSuccessMessage(
        intent.command,
        targetAgents.map((a) => a.name).toList(),
        client.deviceName,
      );
      await _playResponse(successMessage);

      _setState(RaikoVoiceState.idle);
    } catch (e) {
      _setError(e.toString());
    }
  }

  String _buildConfirmationMessage(
    String command,
    List<String> agentNames,
    String userName,
  ) {
    final targets = agentNames.join(' and ');
    switch (command) {
      case 'lock':
        return 'Locking $targets, $userName.';
      case 'sleep':
        return 'Putting $targets to sleep, $userName.';
      case 'restart':
        return 'Restarting $targets, $userName.';
      case 'shutdown':
        return 'Shutting down $targets, $userName.';
      default:
        return 'Executing $command on $targets, $userName.';
    }
  }

  String _buildSuccessMessage(
    String command,
    List<String> agentNames,
    String userName,
  ) {
    final targets = agentNames.join(' and ');
    switch (command) {
      case 'lock':
        return 'Successfully locked $targets.';
      case 'sleep':
        return '$targets is now sleeping.';
      case 'restart':
        return '$targets is restarting.';
      case 'shutdown':
        return '$targets is shutting down.';
      default:
        return 'Command executed on $targets.';
    }
  }

  Future<void> _playResponse(String text) async {
    try {
      // TODO: Call backend /tts endpoint with text
      // For now, just a placeholder
      _setState(RaikoVoiceState.speaking);
      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      _setError('Failed to play response: $e');
    }
  }

  void _setState(RaikoVoiceState newState) {
    _state = newState;
    _lastError = null;
    notifyListeners();
  }

  void _setError(String error) {
    _state = RaikoVoiceState.error;
    _lastError = error;
    notifyListeners();
  }

  @override
  Future<void> dispose() async {
    await _wakeWordDetector.dispose();
    await _stt.dispose();
    await _intentParser.dispose();
    await _audioPlayer.dispose();
    super.dispose();
  }
}
