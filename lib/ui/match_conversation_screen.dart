import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/logic/parent_matching_backend_service.dart';

class MatchConversationScreen extends StatefulWidget {
  const MatchConversationScreen({
    super.key,
    required this.profileId,
    required this.profileName,
  });

  final String profileId;
  final String profileName;

  @override
  State<MatchConversationScreen> createState() =>
      _MatchConversationScreenState();
}

class _MatchConversationScreenState extends State<MatchConversationScreen> {
  final TextEditingController _controller = TextEditingController();
  final ParentMatchingBackendService _service =
      BackendServiceFactory.createParentMatchingService();
  final List<_Msg> _messages = [];
  bool _isLoading = true;

  String get _currentUserId {
    final value = AuthService.instance.currentUser?.uid.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'local-parent-user';
  }

  String get _currentUserName {
    final value = AuthService.instance.currentUser?.displayName.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
    return 'Ich';
  }

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final items = await _service.fetchMessages(
      profileId: widget.profileId,
      userId: _currentUserId,
    );
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(items.map((item) {
          final text = (item['content'] ?? '').toString();
          final authorUserId = (item['authorUserId'] ?? '').toString();
          return _Msg(text: text, isMe: authorUserId == _currentUserId);
        }));
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final optimistic = _Msg(text: text, isMe: true);

    setState(() {
      _messages.add(optimistic);
      _controller.clear();
    });

    final sent = await _service.sendMessage(
      profileId: widget.profileId,
      userId: _currentUserId,
      userName: _currentUserName,
      content: text,
    );
    if (!mounted) return;

    if (sent == null) {
      setState(() {
        _messages.remove(optimistic);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nachricht konnte nicht gesendet werden.'),
        ),
      );
      return;
    }

    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Chat mit ${widget.profileName}'),
        actions: [
          IconButton(
            tooltip: 'Aktualisieren',
            onPressed: _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final align = msg.isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft;
                      final color = msg.isMe
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest;

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
                    onPressed: () => _send(),
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
