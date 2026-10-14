import 'json.dart';

Json? _lastOfType(List<Json> parts, String type) {
  for (var i = parts.length - 1; i >= 0; i--) {
    if (parts[i]['type'] == type) return parts[i];
  }
  return null;
}

Json? _toolPart(List<Json> parts, Object? callId) {
  for (var i = parts.length - 1; i >= 0; i--) {
    if (parts[i]['toolCallId'] == callId) return parts[i];
  }
  return null;
}

bool applyChunk(List<Json> parts, Json chunk) {
  final type = chunk['type'];
  switch (type) {
    case 'text-start':
      parts.add({'type': 'text', 'text': '', 'state': 'streaming'});
    case 'text-delta':
      final last = _lastOfType(parts, 'text');
      if (last != null) {
        last['text'] = '${last['text'] ?? ''}${chunk['delta'] ?? ''}';
      } else {
        parts.add({
          'type': 'text',
          'text': chunk['delta'] ?? '',
          'state': 'streaming',
        });
      }
    case 'text-end':
      _lastOfType(parts, 'text')?['state'] = 'done';
    case 'reasoning-start':
      parts.add({'type': 'reasoning', 'text': '', 'state': 'streaming'});
    case 'reasoning-delta':
      final last = _lastOfType(parts, 'reasoning');
      if (last != null) {
        last['text'] = '${last['text'] ?? ''}${chunk['delta'] ?? ''}';
      } else {
        parts.add({
          'type': 'reasoning',
          'text': chunk['delta'] ?? '',
          'state': 'streaming',
        });
      }
    case 'reasoning-end':
      _lastOfType(parts, 'reasoning')?['state'] = 'done';
    case 'tool-input-start':
      parts.add({
        'type': 'tool-${chunk['toolName']}',
        'toolCallId': chunk['toolCallId'],
        'toolName': chunk['toolName'],
        'state': 'input-streaming',
      });
    case 'tool-input-delta':
      _toolPart(parts, chunk['toolCallId'])?['input'] = chunk['input'];
    case 'tool-input-available':
      final part = _toolPart(parts, chunk['toolCallId']);
      if (part != null) {
        part['state'] = 'input-available';
        part['input'] = chunk['input'];
      } else {
        parts.add({
          'type': 'tool-${chunk['toolName']}',
          'toolCallId': chunk['toolCallId'],
          'toolName': chunk['toolName'],
          'state': 'input-available',
          'input': chunk['input'],
        });
      }
    case 'tool-input-error':
      final part = _toolPart(parts, chunk['toolCallId']);
      if (part != null) {
        part['state'] = 'output-error';
        part['errorText'] = chunk['errorText'];
        part['input'] = chunk['input'];
      } else {
        parts.add({
          'type': 'tool-${chunk['toolName']}',
          'toolCallId': chunk['toolCallId'],
          'toolName': chunk['toolName'],
          'state': 'output-error',
          'input': chunk['input'],
          'errorText': chunk['errorText'],
        });
      }
    case 'tool-output-available':
      final part = _toolPart(parts, chunk['toolCallId']);
      if (part != null) {
        part['state'] = 'output-available';
        part['output'] = chunk['output'];
      }
    case 'tool-output-error':
      final part = _toolPart(parts, chunk['toolCallId']);
      if (part != null) {
        part['state'] = 'output-error';
        part['errorText'] = chunk['errorText'];
      }
    case 'tool-output-denied':
      _toolPart(parts, chunk['toolCallId'])?['state'] = 'output-denied';
    case 'start-step' || 'step-start':
      parts.add({'type': 'step-start'});
    default:
      return false;
  }
  return true;
}

String? toolNameOf(Json part) {
  final type = part['type'];
  if (type is! String || !type.startsWith('tool-')) return null;
  return (part['toolName'] as String?) ?? type.substring(5);
}

String messageText(Json message) => [
  for (final p in (message['parts'] as List? ?? const []))
    if (p is Map && p['type'] == 'text') p['text'] as String? ?? '',
].join('\n\n').trim();
