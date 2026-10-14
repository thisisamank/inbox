import 'dart:convert';

import 'package:api/api.dart';
import 'package:test/test.dart';

void main() {
  test('agentUri keeps the mailbox id raw like the agents SDK', () {
    expect(
      agentUri(
        Uri.parse('https://inbox.example.workers.dev'),
        'aman@akxr.in',
      ).toString(),
      'wss://inbox.example.workers.dev/agents/email-agent/aman@akxr.in',
    );
    expect(agentUri(Uri.parse('http://localhost:5173'), 'a@b.c').scheme, 'ws');
  });

  test('applyChunk builds text and tool parts like applyChunkToParts', () {
    final parts = <Json>[];
    for (final chunk in <Json>[
      {'type': 'start', 'messageId': 'm1'},
      {'type': 'start-step'},
      {
        'type': 'tool-input-start',
        'toolCallId': 'c1',
        'toolName': 'list_emails',
      },
      {
        'type': 'tool-input-available',
        'toolCallId': 'c1',
        'toolName': 'list_emails',
        'input': {'folder': 'inbox'},
      },
      {
        'type': 'tool-output-available',
        'toolCallId': 'c1',
        'output': {'count': 2},
      },
      {'type': 'text-start', 'id': 't'},
      {'type': 'text-delta', 'id': 't', 'delta': 'Two '},
      {'type': 'text-delta', 'id': 't', 'delta': 'emails.'},
      {'type': 'text-end', 'id': 't'},
      {'type': 'finish'},
    ]) {
      applyChunk(parts, chunk);
    }
    expect(parts.map((p) => p['type']), [
      'step-start',
      'tool-list_emails',
      'text',
    ]);
    expect(parts[1]['state'], 'output-available');
    expect(toolNameOf(parts[1]), 'list_emails');
    expect(parts[2]['text'], 'Two emails.');
    expect(parts[2]['state'], 'done');
  });

  test(
    'tool errors mark the part as failed and unknown chunks are ignored',
    () {
      final parts = <Json>[];
      applyChunk(parts, {
        'type': 'tool-input-available',
        'toolCallId': 'c',
        'toolName': 'get_email',
        'input': {},
      });
      applyChunk(parts, {
        'type': 'tool-output-error',
        'toolCallId': 'c',
        'errorText': 'not found',
      });
      expect(parts.single['state'], 'output-error');
      expect(applyChunk(parts, {'type': 'unknown-thing'}), isFalse);
    },
  );

  test(
    'buildChatRequest sends the full history and drops local placeholders',
    () {
      final history = <Json>[
        {
          'id': 'u1',
          'role': 'user',
          'parts': [
            {'type': 'text', 'text': 'hi'},
          ],
          'metadata': {'keep': true},
        },
        {
          'id': 'a1',
          'role': 'assistant',
          'parts': [
            {'type': 'text', 'text': 'hello'},
          ],
        },
        {'id': 'stream-x', 'role': 'assistant', 'parts': []},
      ];
      final request = buildChatRequest(
        history,
        'next',
        userMessageId: 'u2',
        requestId: 'r1',
      );
      expect(request.frame['type'], 'cf_agent_use_chat_request');
      final body =
          jsonDecode((request.frame['init'] as Map)['body'] as String) as Map;
      expect(body['trigger'], 'submit-message');
      final sent = (body['messages'] as List).cast<Map>();
      expect(sent.map((m) => m['id']), ['u1', 'a1', 'u2']);
      expect(sent.first['metadata'], {'keep': true});
      expect(messageText(sent.last.cast<String, dynamic>()), 'next');
    },
  );
}
