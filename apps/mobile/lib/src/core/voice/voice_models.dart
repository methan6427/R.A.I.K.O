enum RaikoVoiceState {
  idle,
  listening,
  processing,
  confirming,
  executing,
  speaking,
  error,
}

class RaikoIntent {
  final String command;
  final String targetAgent;
  final double confidence;
  final String? args;

  RaikoIntent({
    required this.command,
    required this.targetAgent,
    required this.confidence,
    this.args,
  });
}

class RaikoVoiceResponse {
  final String text;
  final DateTime timestamp;
  final bool isError;

  RaikoVoiceResponse({
    required this.text,
    required this.timestamp,
    this.isError = false,
  });
}
