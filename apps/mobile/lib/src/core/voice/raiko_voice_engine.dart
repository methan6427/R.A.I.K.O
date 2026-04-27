import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../network/raiko_ws_client.dart';
import '../remote/anydesk_integration.dart';
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
  late HttpClient _httpClient;
  late AnyDeskIntegration _anydesk;

  RaikoVoiceState _state = RaikoVoiceState.idle;
  String? _lastError;
  bool _initialized = false;

  // UI display state
  String? _transcribedText;
  RaikoIntent? _parsedIntent;
  String? _responseText;

  RaikoVoiceEngine({
    required this.client,
    required this.settings,
  });

  RaikoVoiceState get state => _state;
  String? get lastError => _lastError;
  bool get isInitialized => _initialized;
  String? get transcribedText => _transcribedText;
  RaikoIntent? get parsedIntent => _parsedIntent;
  String? get responseText => _responseText;

  Future<void> initialize({
    String? porcupineAccessKey,
  }) async {
    try {
      _wakeWordDetector = RaikoWakeWordDetector();
      _stt = RaikoSpeechToText();
      _intentParser = RaikoIntentParser();
      _audioPlayer = AudioPlayer();
      _httpClient = HttpClient();
      _anydesk = AnyDeskIntegration();

      if (porcupineAccessKey != null && porcupineAccessKey.isNotEmpty) {
        await _wakeWordDetector.initialize(porcupineAccessKey);
      }
      await _stt.initialize();
      await _intentParser.initialize(client.baseHttpUrl, client.authToken);

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

  /// Open remote desktop via AnyDesk
  Future<void> openRemoteDesktop() async {
    if (!_initialized) {
      _setError('Voice engine not initialized');
      return;
    }
    await _openRemoteDesktop();
  }

  /// Process a text command directly (for testing without speech)
  Future<void> processTextCommand(String text) async {
    if (!_initialized) {
      _setError('Voice engine not initialized');
      return;
    }

    try {
      await _processTranscribedText(text);
    } catch (e) {
      _setError(e.toString());
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

      await _processTranscribedText(transcribedText);
    } catch (e) {
      _setError(e.toString());
    }
  }

  Future<void> _processTranscribedText(String transcribedText) async {
    try {
      _transcribedText = transcribedText;
      notifyListeners();

      _setState(RaikoVoiceState.processing);

      // Parse intent
      final intent = await _intentParser.parse(
        transcribedText,
        client.agents.map((a) => a.name).toList(),
        client.deviceName,
      );

      _parsedIntent = intent;
      notifyListeners();

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

      if (intent.command == 'open_remote_desktop') {
        await _openRemoteDesktop();
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
      // Select the target agent before sending command
      client.updateSelectedAgent(targetAgents.first.id);
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
      case 'wake_up':
        return 'Waking up $targets, $userName.';
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
      case 'wake_up':
        return 'Waking up $targets. It may take a moment to respond.';
      case 'open_remote_desktop':
        return 'Opening AnyDesk remote desktop.';
      default:
        return 'Command executed on $targets.';
    }
  }

  Future<void> _openRemoteDesktop() async {
    try {
      _setState(RaikoVoiceState.executing);

      final launched = await _anydesk.launch();
      if (launched) {
        _setState(RaikoVoiceState.speaking);
        await _playResponse('Opening AnyDesk for remote desktop access.');
        _setState(RaikoVoiceState.idle);
      } else {
        _setError('AnyDesk not found or cannot launch. Please install it first.');
      }
    } catch (e) {
      _setError('Failed to open remote desktop: $e');
    }
  }

  Future<void> _playResponse(String text) async {
    try {
      _responseText = text;
      _setState(RaikoVoiceState.speaking);
      notifyListeners();

      // Fetch audio from backend TTS endpoint
      final audioPath = await _fetchAudioFromBackend(text);
      if (audioPath == null) {
        await Future.delayed(const Duration(seconds: 1));
        _setState(RaikoVoiceState.idle);
        return;
      }

      // Play audio
      await _audioPlayer.play(DeviceFileSource(audioPath));

      // Wait for playback to finish
      await _audioPlayer.onPlayerComplete.first;
      _setState(RaikoVoiceState.idle);
    } catch (e) {
      if (kDebugMode) {
        print('TTS playback error: $e');
      }
      // Don't fail the command if TTS fails - return to idle normally
      _setState(RaikoVoiceState.idle);
    }
  }

  Future<String?> _fetchAudioFromBackend(String text) async {
    try {
      // Coolify backend redirects HTTP→HTTPS, but skip upgrade for local dev hosts
      final rawUrl = client.baseHttpUrl;
      final isLocalHost = RegExp(r'^http://(localhost|127\.0\.0\.1|10\.0\.2\.2|192\.168\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.)').hasMatch(rawUrl);
      final backendUrl = isLocalHost ? rawUrl : rawUrl.replaceFirst(RegExp(r'^http://'), 'https://');
      final baseUrl = backendUrl.endsWith('/') ? backendUrl : '$backendUrl/';
      final uri = Uri.parse(baseUrl).resolve('api/tts');
      final request = await _httpClient.postUrl(uri);
      request.headers.set('Content-Type', 'application/json');
      request.headers.set('x-raiko-token', client.authToken);

      final body = jsonEncode({
        'text': text,
        'voice': 'en_US-ryan-high',
        'speed': 1.0,
      });
      request.contentLength = body.length;
      request.write(body);

      final response = await request.close().timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 400) {
        final audioBytes = await response.expand((chunk) => chunk).toList();
        final dir = await getTemporaryDirectory();
        final file =
            File('${dir.path}/raiko-audio-${DateTime.now().millisecondsSinceEpoch}.wav');
        await file.writeAsBytes(audioBytes);
        return file.path;
      } else {
        final errorBody = await response.transform(utf8.decoder).join();
        if (kDebugMode) {
          print('TTS ERROR: HTTP ${response.statusCode} - $errorBody');
        }
        throw Exception('TTS failed: HTTP ${response.statusCode}\n$errorBody');
      }
    } catch (e) {
      if (kDebugMode) {
        print('TTS fetch error: $e');
      }
      return null;
    }
  }

  void _setState(RaikoVoiceState newState) {
    _state = newState;
    _lastError = null;

    // Clear display state when returning to idle
    if (newState == RaikoVoiceState.idle) {
      _transcribedText = null;
      _parsedIntent = null;
      _responseText = null;
    }

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
