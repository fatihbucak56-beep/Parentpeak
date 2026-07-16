import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/logic/product_metrics_service.dart';
import 'package:trusted_circle_demo/logic/todo_backend_service.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/entwicklung_impulse_screen.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final TodoBackendService _todoService =
      BackendServiceFactory.createTodoService();
  List<Map<String, dynamic>> _todos = [];
  bool _loading = true;
  String? _syncError;
  Timer? _autoSyncRetryTimer;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  Future<void> _loadTodos() async {
    final todos = await _todoService.fetchTodos();
    if (!mounted) return;
    setState(() {
      _todos = todos;
      _loading = false;
      _syncError = _todoService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  void _scheduleAutoSyncRetry() {
    _autoSyncRetryTimer?.cancel();
    final hasSyncError = _syncError != null && _syncError!.trim().isNotEmpty;
    if (!hasSyncError) return;
    _autoSyncRetryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _loadTodos();
    });
  }

  Future<void> _openDevelopmentFallback() async {
    await ProductMetricsService.instance.recordUtilityFallbackRouteTap(
      surface: 'todo',
      from: 'todo_sync_error',
      to: 'development',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const EntwicklungImpulseScreen(initialTabIndex: 1),
      ),
    );
  }

  Future<void> _openChatFallback() async {
    await ProductMetricsService.instance.recordUtilityFallbackRouteTap(
      surface: 'todo',
      from: 'todo_sync_error',
      to: 'chat',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  Future<void> _openCalendarFallback() async {
    await ProductMetricsService.instance.recordUtilityFallbackRouteTap(
      surface: 'todo',
      from: 'todo_sync_error',
      to: 'calendar',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  @override
  void dispose() {
    _autoSyncRetryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    if (_controller.text.trim().isEmpty) return;
    final title = _controller.text.trim();
    _controller.clear();

    final created = await _todoService.addTodo(
      title: title,
      assignee: 'Familie',
      category: 'Allgemein',
    );
    if (!mounted) return;

    setState(() {
      _todos.insert(0, created);
      _syncError = _todoService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  Future<void> _toggleDone(int index, bool value) async {
    final id = _todos[index]['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _todos[index]['done'] = value);
    await _todoService.updateDone(id, value);
    if (!mounted) return;
    setState(() {
      _syncError = _todoService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  Future<void> _removeTodo(int index) async {
    final id = _todos[index]['id']?.toString();
    setState(() => _todos.removeAt(index));
    if (id != null && id.isNotEmpty) {
      await _todoService.deleteTodo(id);
    }
    if (!mounted) return;
    setState(() {
      _syncError = _todoService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('To-Do Liste'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadTodos,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Synchronisieren',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_syncError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: Icon(
                    Icons.cloud_done_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Lokaler Modus aktiv'),
                  subtitle: Text(_syncError!),
                  trailing: TextButton(
                    onPressed: _loadTodos,
                    child: const Text('Erneut versuchen'),
                  ),
                ),
              ),
            ),
          if (_syncError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aenderungen bleiben lokal gespeichert und werden beim naechsten Sync automatisch nachgesendet.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _openChatFallback,
                          icon: const Icon(Icons.tips_and_updates_rounded),
                          label: const Text('Zur KI-Beratung'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openDevelopmentFallback,
                          icon: const Icon(Icons.insights_rounded),
                          label: const Text('Zu Entwicklung'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _openCalendarFallback,
                          icon: const Icon(Icons.calendar_month_rounded),
                          label: const Text('Zum Kalender'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // Eingabe-Feld
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Neue Aufgabe hinzufügen...',
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.add_task,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      onSubmitted: (_) => _addTodo(),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addTodo,
                    icon: const Icon(Icons.add),
                    label: const Text(''),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Todo-Items
          ..._todos.asMap().entries.map((entry) {
            final i = entry.key;
            final todo = entry.value;
            final isDone = todo['done'] as bool;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: isDone ? 0 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isDone
                      ? BorderSide(color: Colors.grey[300]!, width: 1)
                      : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Checkbox(
                    value: isDone,
                    onChanged: (val) {
                      _toggleDone(i, val ?? false);
                    },
                    shape: const RoundedRectangleBorder(),
                  ),
                  title: Text(
                    todo['title'] as String,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      decoration: isDone ? TextDecoration.lineThrough : null,
                      color: isDone ? Colors.grey : null,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            todo['assignee'] as String,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          todo['category'] as String,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () {
                      _removeTodo(i);
                    },
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
