import 'package:trusted_circle_demo/logic/pedagogical_chat_backend.dart';

Future<void> main() async {
  final backend = PedagogicalChatBackend();

  final neutral = await backend
      .streamReply(history: const [], userMessage: 'Konflikt gewaltfrei loesen')
      .join();
  final crisis = await backend
      .streamReply(history: const [], userMessage: 'Ich habe Angst die Kontrolle zu verlieren')
      .join();

  print('NEUTRAL: $neutral');
  print('---');
  print('CRISIS: $crisis');
}
