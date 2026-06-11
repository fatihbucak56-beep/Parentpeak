import 'package:flutter/material.dart';

class MatchConversationScreen extends StatefulWidget {
  const MatchConversationScreen({super.key, required this.profileName});

  final String profileName;

  @override
  State<MatchConversationScreen> createState() => _MatchConversationScreenState();
}

class _MatchConversationScreenState extends State<MatchConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<_Msg> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(
      _Msg(
        text:
            'Hi! Schoen, dass wir gematcht haben. Wollen wir uns fuer einen Spielplatz-Treff austauschen?',
        isMe: false,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_Msg(text: text, isMe: true));
      _controller.clear();
    });

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _messages.add(
          const _Msg(
            text: 'Klingt gut! Lass uns einen passenden Termin abstimmen.',
            isMe: false,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat mit ${widget.profileName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final align =
                    msg.isMe ? Alignment.centerRight : Alignment.centerLeft;
                final color = msg.isMe
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceVariant;

                return Align(
                  alignment: align,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nachricht schreiben...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Msg {
  const _Msg({required this.text, required this.isMe});

  final String text;
  final bool isMe;
}