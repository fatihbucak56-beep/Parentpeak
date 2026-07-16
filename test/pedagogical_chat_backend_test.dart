import 'package:flutter_test/flutter_test.dart';
import 'package:trusted_circle_demo/logic/pedagogical_chat_backend.dart';

void main() {
  group('PedagogicalChatBackend safety routing', () {
    test('treats ordinary exhaustion as supportive, not crisis', () async {
      final backend = PedagogicalChatBackend();

      final chunks = await backend
          .streamReply(
            history: const [],
            userMessage: 'Ich kann nicht mehr und bin so erschöpft.',
          )
          .toList();

      final response = chunks.join();

      expect(response, contains('Du musst da nicht stark sein'));
      expect(response, contains('du bist damit nicht allein'));
      expect(response, isNot(contains('112')));
      expect(response, isNot(contains('Telefonseelsorge')));
    });

    test('keeps acute danger on the crisis path', () async {
      final backend = PedagogicalChatBackend();

      final chunks = await backend
          .streamReply(
            history: const [],
            userMessage: 'Ich will meinem Kind etwas antun.',
          )
          .toList();

      final response = chunks.join();

      expect(response, contains('akuten Belastung'));
      expect(response, contains('112'));
      expect(response, contains('Telefonseelsorge'));
    });
  });
}