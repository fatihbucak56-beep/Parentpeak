import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/logic/shopping_backend_service.dart';
import 'package:trusted_circle_demo/logic/todo_backend_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
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
  }

  Future<void> _toggleEntry(int index, bool newValue) async {
    if (_mode == _OrganizationMode.todos) {
      final id = _todos[index]['id']?.toString();
      if (id == null || id.isEmpty) return;
      setState(() => _todos[index]['done'] = newValue);
      await _todoService.updateDone(id, newValue);
      if (!mounted) return;
      setState(() => _todoSyncError = _todoService.lastSyncError);
      return;
    }

    final id = _shoppingItems[index]['id']?.toString();
    if (id == null || id.isEmpty) return;
    setState(() => _shoppingItems[index]['checked'] = newValue);
    await _shoppingService.updateChecked(id, newValue);
    if (!mounted) return;
    setState(() => _shoppingSyncError = _shoppingService.lastSyncError);
  }

  Future<void> _deleteEntry(int index) async {
    if (_mode == _OrganizationMode.todos) {
      final id = _todos[index]['id']?.toString();
      setState(() => _todos.removeAt(index));
      if (id != null && id.isNotEmpty) {
        await _todoService.deleteTodo(id);
      }
      if (!mounted) return;
      setState(() => _todoSyncError = _todoService.lastSyncError);
      return;
    }

    final id = _shoppingItems[index]['id']?.toString();
    setState(() => _shoppingItems.removeAt(index));
    if (id != null && id.isNotEmpty) {
      await _shoppingService.deleteItem(id);
    }
    if (!mounted) return;
    setState(() => _shoppingSyncError = _shoppingService.lastSyncError);
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

    final openItems =
        activeItems.where((item) => !(item[completeKey] as bool? ?? false));
    final doneItems =
        activeItems.where((item) => item[completeKey] as bool? ?? false);

    final syncError = isTodos ? _todoSyncError : _shoppingSyncError;

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
          if (syncError != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.amber[100],
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  leading: const Icon(Icons.cloud_off_rounded),
                  title: const Text('Server-Sync fehlgeschlagen'),
                  subtitle: Text(syncError),
                  trailing: TextButton(
                    onPressed: _loadData,
                    child: const Text('Retry'),
                  ),
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
            else
              ...activeItems.asMap().entries.map((entry) {
                final i = entry.key;
                final item = entry.value;
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
                        onChanged: (val) => _toggleEntry(i, val ?? false),
                      ),
                      title: Text(
                        (item[titleKey] ?? '').toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          decoration: isDone ? TextDecoration.lineThrough : null,
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
                        onPressed: () => _deleteEntry(i),
                      ),
                    ),
                  ),
                );
              }),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}