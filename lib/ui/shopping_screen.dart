import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/l10n/app_localizations.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  final List<Map<String, dynamic>> _items = [
    {'name': 'Milch', 'checked': false, 'category': 'Lebensmittel'},
    {'name': 'Brot', 'checked': false, 'category': 'Lebensmittel'},
    {'name': 'Äpfel', 'checked': true, 'category': 'Obst & Gemüse'},
    {'name': 'Windeln', 'checked': false, 'category': 'Baby'},
    {'name': 'Zahnpasta', 'checked': false, 'category': 'Drogerie'},
  ];

  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _items.insert(0, {
        'name': _controller.text.trim(),
        'checked': false,
        'category': 'Allgemein',
      });
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unchecked = _items.where((item) => !(item['checked'] as bool)).toList();
    final checked = _items.where((item) => item['checked'] as bool).toList();
    
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
                      hintText: 'Artikel zur Liste hinzufügen...',
                      prefixIcon: Icon(Icons.shopping_cart_outlined, color: theme.colorScheme.primary),
                    ),
                    onSubmitted: (_) => _addItem(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _addItem,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    shape: const CircleBorder(),
                  ),
                  child: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          if (unchecked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Noch zu kaufen (${unchecked.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                ...unchecked.map((item) => _buildItem(item, theme)),
                if (checked.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Im Warenkorb (${checked.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...checked.map((item) => _buildItem(item, theme)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> item, ThemeData theme) {
    final isChecked = item['checked'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isChecked ? Colors.grey[300]! : Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Checkbox(
            value: isChecked,
            onChanged: (val) {
              setState(() => item['checked'] = val ?? false);
            },
            shape: const CircleBorder(),
          ),
          title: Text(
            item['name'] as String,
            style: theme.textTheme.bodyLarge?.copyWith(
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked ? Colors.grey : null,
            ),
          ),
          subtitle: Text(
            item['category'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
            onPressed: () {
              setState(() => _items.remove(item));
            },
          ),
        ),
      ),
    );
  }
}
