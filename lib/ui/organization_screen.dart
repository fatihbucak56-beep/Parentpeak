import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/logic/product_metrics_service.dart';
import 'package:trusted_circle_demo/logic/shopping_backend_service.dart';
import 'package:trusted_circle_demo/logic/todo_backend_service.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/entwicklung_impulse_screen.dart';

enum _OrganizationMode { todos, shopping }

class OrganizationScreen extends StatefulWidget {
  const OrganizationScreen({super.key});

  @override
  State<OrganizationScreen> createState() => _OrganizationScreenState();
}

class _OrganizationScreenState extends State<OrganizationScreen> {
  final TodoBackendService _todoService =
      BackendServiceFactory.createTodoService();
  final ShoppingBackendService _shoppingService =
      BackendServiceFactory.createShoppingService();

  final TextEditingController _controller = TextEditingController();

  _OrganizationMode _mode = _OrganizationMode.todos;
  List<Map<String, dynamic>> _todos = [];
  List<Map<String, dynamic>> _shoppingItems = [];
  bool _loading = true;
  String? _todoSyncError;
  String? _shoppingSyncError;
  Timer? _autoSyncRetryTimer;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _autoSyncRetryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final todosFuture = _todoService.fetchTodos();
    final shoppingFuture = _shoppingService.fetchItems();

    final result = await Future.wait([todosFuture, shoppingFuture]);
    if (!mounted) return;

    setState(() {
      _todos = List<Map<String, dynamic>>.from(result[0] as List);
      _shoppingItems = List<Map<String, dynamic>>.from(result[1] as List);
      _todoSyncError = _todoService.lastSyncError;
      _shoppingSyncError = _shoppingService.lastSyncError;
      _loading = false;
    });
    _scheduleAutoSyncRetry();
  }

  void _scheduleAutoSyncRetry() {
    _autoSyncRetryTimer?.cancel();
    final hasSyncError = (_todoSyncError != null && _todoSyncError!.trim().isNotEmpty) ||
        (_shoppingSyncError != null && _shoppingSyncError!.trim().isNotEmpty);
    if (!hasSyncError) return;

    _autoSyncRetryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _loadData();
    });
  }

  Future<void> _openDevelopmentFallback() async {
    await ProductMetricsService.instance.recordUtilityFallbackRouteTap(
      surface: 'organization',
      from: 'organization_sync_error',
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
      surface: 'organization',
      from: 'organization_sync_error',
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
      surface: 'organization',
      from: 'organization_sync_error',
      to: 'calendar',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  Future<void> _addEntry() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();

    if (_mode == _OrganizationMode.todos) {
      final created = await _todoService.addTodo(
        title: text,
        assignee: 'Familie',
        category: 'Allgemein',
      );
      if (!mounted) return;
      setState(() {
        _todos.insert(0, created);
        _todoSyncError = _todoService.lastSyncError;
      });
      _scheduleAutoSyncRetry();
      return;
    }

    final created = await _shoppingService.addItem(
      name: text,
      category: 'Allgemein',
    );
    if (!mounted) return;
    setState(() {
      _shoppingItems.insert(0, created);
      _shoppingSyncError = _shoppingService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  Future<void> _toggleEntry(Map<String, dynamic> item, bool newValue) async {
    if (_mode == _OrganizationMode.todos) {
      final id = item['id']?.toString();
      if (id == null || id.isEmpty) return;
      final idx = _todos.indexWhere((e) => e['id']?.toString() == id);
      if (idx == -1) return;
      setState(() => _todos[idx]['done'] = newValue);
      await _todoService.updateDone(id, newValue);
      if (!mounted) return;
      setState(() => _todoSyncError = _todoService.lastSyncError);
      _scheduleAutoSyncRetry();
      return;
    }

    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;
    final idx = _shoppingItems.indexWhere((e) => e['id']?.toString() == id);
    if (idx == -1) return;
    setState(() => _shoppingItems[idx]['checked'] = newValue);
    await _shoppingService.updateChecked(id, newValue);
    if (!mounted) return;
    setState(() => _shoppingSyncError = _shoppingService.lastSyncError);
    _scheduleAutoSyncRetry();
  }

  Future<void> _deleteEntry(Map<String, dynamic> item) async {
    if (_mode == _OrganizationMode.todos) {
      final id = item['id']?.toString();
      setState(() {
        if (id != null && id.isNotEmpty) {
          _todos.removeWhere((e) => e['id']?.toString() == id);
        } else {
          _todos.remove(item);
        }
      });
      if (id != null && id.isNotEmpty) {
        await _todoService.deleteTodo(id);
      }
      if (!mounted) return;
      setState(() => _todoSyncError = _todoService.lastSyncError);
      _scheduleAutoSyncRetry();
      return;
    }

    final id = item['id']?.toString();
    setState(() {
      if (id != null && id.isNotEmpty) {
        _shoppingItems.removeWhere((e) => e['id']?.toString() == id);
      } else {
        _shoppingItems.remove(item);
      }
    });
    if (id != null && id.isNotEmpty) {
      await _shoppingService.deleteItem(id);
    }
    if (!mounted) return;
    setState(() => _shoppingSyncError = _shoppingService.lastSyncError);
    _scheduleAutoSyncRetry();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTodos = _mode == _OrganizationMode.todos;
    final activeItems = isTodos ? _todos : _shoppingItems;
    final completeKey = isTodos ? 'done' : 'checked';
    final titleKey = isTodos ? 'title' : 'name';
    final subtitleHint = isTodos
        ? 'Neue Aufgabe hinzufügen...'
        : 'Neuen Einkaufsartikel hinzufügen...';

    final openItems = activeItems
        .where((item) => !(item[completeKey] as bool? ?? false))
        .toList();
    final doneItems = activeItems
        .where((item) => item[completeKey] as bool? ?? false)
        .toList();

    final syncError = isTodos ? _todoSyncError : _shoppingSyncError;
    final hasSyncNotice = syncError != null && syncError.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Organisation'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Synchronisieren',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_OrganizationMode>(
            segments: const [
              ButtonSegment<_OrganizationMode>(
                value: _OrganizationMode.todos,
                icon: Icon(Icons.task_alt_rounded),
                label: Text('To-do'),
              ),
              ButtonSegment<_OrganizationMode>(
                value: _OrganizationMode.shopping,
                icon: Icon(Icons.shopping_cart_rounded),
                label: Text('Einkauf'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) {
              setState(() => _mode = selection.first);
            },
          ),
          const SizedBox(height: 12),
          if (hasSyncNotice)
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
                  subtitle: Text(syncError),
                  trailing: TextButton(
                    onPressed: _loadData,
                    child: const Text('Erneut versuchen'),
                  ),
                ),
              ),
            ),
          if (hasSyncNotice)
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
                        hintText: subtitleHint,
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          isTodos
                              ? Icons.add_task_rounded
                              : Icons.add_shopping_cart_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      onSubmitted: (_) => _addEntry(),
                    ),
                  ),
                  FilledButton(
                    onPressed: _addEntry,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            Row(
              children: [
                _SummaryChip(
                  label: 'Offen',
                  value: openItems.length,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                _SummaryChip(
                  label: 'Erledigt',
                  value: doneItems.length,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeItems.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Center(
                  child: Text(
                    isTodos
                        ? 'Noch keine Aufgaben vorhanden.'
                        : 'Noch keine Einkaufseintraege vorhanden.',
                  ),
                ),
              )
            else ...[
              if (openItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Offen',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ...openItems.map((item) {
                final isDone = item[completeKey] as bool? ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: isDone ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isDone
                          ? BorderSide(color: Colors.grey[300]!, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (val) => _toggleEntry(item, val ?? false),
                      ),
                      title: Text(
                        (item[titleKey] ?? '').toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        (item['category'] ?? 'Allgemein').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(item),
                      ),
                    ),
                  ),
                );
              }),
              if (doneItems.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 8),
                  child: Text(
                    'Erledigt',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
              ...doneItems.map((item) {
                final isDone = item[completeKey] as bool? ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    elevation: isDone ? 0 : 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isDone
                          ? BorderSide(color: Colors.grey[300]!, width: 1)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (val) => _toggleEntry(item, val ?? false),
                      ),
                      title: Text(
                        (item[titleKey] ?? '').toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration:
                              isDone ? TextDecoration.lineThrough : null,
                          color: isDone ? Colors.grey : null,
                        ),
                      ),
                      subtitle: Text(
                        (item['category'] ?? 'Allgemein').toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _deleteEntry(item),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
