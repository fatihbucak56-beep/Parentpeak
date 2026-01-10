import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<Map<String, dynamic>> _todos = [
    {'title': 'Hausaufgaben machen', 'done': false, 'assignee': 'Leon', 'category': 'Schule'},
    {'title': 'Arzttermin buchen', 'done': false, 'assignee': 'Mama', 'category': 'Gesundheit'},
    {'title': 'Fußballschuhe kaufen', 'done': true, 'assignee': 'Papa', 'category': 'Sport'},
    {'title': 'Geburtstag vorbereiten', 'done': false, 'assignee': 'Familie', 'category': 'Ereignis'},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTodo() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _todos.insert(0, {
        'title': _controller.text.trim(),
        'done': false,
        'assignee': 'Familie',
        'category': 'Allgemein',
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.colorScheme.primary.withOpacity(0.03), Colors.white],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Neue Aufgabe hinzufügen...',
                      prefixIcon: Icon(Icons.add_task, color: theme.colorScheme.primary),
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _addTodo,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _todos.length,
              itemBuilder: (_, i) {
                final todo = _todos[i];
                final isDone = todo['done'] as bool;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDone ? Colors.grey[300]! : Colors.grey[200]!,
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Checkbox(
                        value: isDone,
                        onChanged: (val) {
                          setState(() => _todos[i]['done'] = val ?? false);
                        },
                        shape: const CircleBorder(),
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                          setState(() => _todos.removeAt(i));
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
