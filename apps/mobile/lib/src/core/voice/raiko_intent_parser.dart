import 'package:google_generative_ai/google_generative_ai.dart';
import 'voice_models.dart';

class RaikoIntentParser {
  late GenerativeModel _model;

  Future<void> initialize(String apiKey) async {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: apiKey,
      );
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
      final systemPrompt = '''You are R.A.I.K.O, an AI operations assistant.

Connected agents: ${availableAgents.join(', ')}
User name: $userName

Your role: Parse device control commands.
Available commands: lock, sleep, restart, shutdown, open_app, set_name, ask_clarification

When the user says a command, respond ONLY with these lines (no extra text):
COMMAND: <command>
TARGET: <agent_name or "all">
CONFIDENCE: <0.0-1.0>

Examples:
"lock the laptop" → COMMAND: lock / TARGET: laptop / CONFIDENCE: 0.95
"restart all devices" → COMMAND: restart / TARGET: all / CONFIDENCE: 0.9
"raiko my name is adam" → COMMAND: set_name / TARGET: adam / CONFIDENCE: 0.95
"what time is it" → COMMAND: ask_clarification / CONFIDENCE: 0.3''';

      final prompt = '''$systemPrompt

User said: $transcribedText''';

      final response = await _model.generateContent([
        Content('user', [TextPart(prompt)]),
      ]);

      return _parseResponse(response.text ?? '');
    } catch (e) {
      throw Exception('Intent parsing failed: $e');
    }
  }

  RaikoIntent _parseResponse(String response) {
    final lines = response.split('\n');
    String command = 'ask_clarification';
    String target = '';
    double confidence = 0.0;

    for (final line in lines) {
      if (line.startsWith('COMMAND:')) {
        command = line.replaceFirst('COMMAND:', '').trim().split('/')[0].trim();
      } else if (line.startsWith('TARGET:')) {
        target = line.replaceFirst('TARGET:', '').trim().split('/')[0].trim();
      } else if (line.startsWith('CONFIDENCE:')) {
        try {
          confidence = double.parse(
            line.replaceFirst('CONFIDENCE:', '').trim().split('/')[0].trim(),
          );
        } catch (e) {
          confidence = 0.0;
        }
      }
    }

    return RaikoIntent(
      command: command,
      targetAgent: target,
      confidence: confidence,
    );
  }

  Future<void> dispose() async {
    // Cleanup if needed
  }
}
