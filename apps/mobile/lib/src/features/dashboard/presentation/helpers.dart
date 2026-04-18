import 'package:flutter/material.dart';
import 'package:shared_theme/shared_theme.dart';

Color statusColor(String status) {
  switch (status) {
    case 'success':
    case 'online':
      return RaikoColors.success;
    case 'failed':
    case 'offline':
      return RaikoColors.danger;
    default:
      return RaikoColors.warning;
  }
}

String formatTimestamp(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.isEmpty ? 'n/a' : value;
  }

  final local = parsed.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatTimeAgo(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return value.isEmpty ? 'n/a' : value;
  }

  final diff = DateTime.now().difference(parsed);
  if (diff.inSeconds < 60) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
