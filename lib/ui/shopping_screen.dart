import 'dart:async';

import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/logic/auth_service.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';
import 'package:trusted_circle_demo/logic/product_metrics_service.dart';
import 'package:trusted_circle_demo/logic/shopping_backend_service.dart';
import 'package:trusted_circle_demo/widgets/language_change_mixin.dart';
import 'package:trusted_circle_demo/main.dart';
import 'package:trusted_circle_demo/l10n/app_localizations_all.dart';
import 'package:trusted_circle_demo/ui/calendar_screen.dart';
import 'package:trusted_circle_demo/ui/chat_screen.dart';
import 'package:trusted_circle_demo/ui/entwicklung_impulse_screen.dart';

class ShoppingScreen extends StatefulWidget {
  const ShoppingScreen({super.key});

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen>
    with LanguageChangeMixin<ShoppingScreen> {
  final ShoppingBackendService _shoppingService =
      BackendServiceFactory.createShoppingService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _syncError;
  Timer? _autoSyncRetryTimer;

  final TextEditingController _controller = TextEditingController();

  String _t(String key) {
    return AppStringsManager.getString(languageService.currentLanguage, key);
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    final items = await _shoppingService.fetchItems();
    if (!mounted) return;

    setState(() {
      _items = items;
      _loading = false;
      _syncError = _shoppingService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  void _scheduleAutoSyncRetry() {
    _autoSyncRetryTimer?.cancel();
    final hasSyncError = _syncError != null && _syncError!.trim().isNotEmpty;
    if (!hasSyncError) return;
    _autoSyncRetryTimer = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      _loadItems();
    });
  }

  Future<void> _openDevelopmentFallback() async {
    await ProductMetricsService.instance.recordUtilityFallbackRouteTap(
      surface: 'shopping',
      from: 'shopping_sync_error',
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
      surface: 'shopping',
      from: 'shopping_sync_error',
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
      surface: 'shopping',
      from: 'shopping_sync_error',
      to: 'calendar',
      userId: AuthService.instance.currentUser?.uid,
    );
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalendarScreen()),
    );
  }

  Future<void> _toggleItemChecked(Map<String, dynamic> item, bool checked) async {
    setState(() => item['checked'] = checked);
    final id = item['id']?.toString();
    if (id != null && id.isNotEmpty) {
      await _shoppingService.updateChecked(id, checked);
    }
    if (!mounted) return;
    setState(() {
      _syncError = _shoppingService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  @override
  void dispose() {
    _autoSyncRetryTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    if (_controller.text.trim().isEmpty) return;
    final name = _controller.text.trim();
    _controller.clear();

    final created = await _shoppingService.addItem(
      name: name,
      category: _t('category_general'),
    );
    if (!mounted) return;

    setState(() {
      _items.insert(0, created);
      _syncError = _shoppingService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
  }

  Future<void> _deleteItem(int index) async {
    final item = _items[index];
    final id = item['id']?.toString();
    setState(() => _items.removeAt(index));
    if (id != null && id.isNotEmpty) {
      await _shoppingService.deleteItem(id);
    }
    if (!mounted) return;
    setState(() {
      _syncError = _shoppingService.lastSyncError;
    });
    _scheduleAutoSyncRetry();
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      SnackBar(
        content: Text('${item['name']} ${_t('deleted')}'),
        action: SnackBarAction(
          label: _t('undo'),
          onPressed: () {
            if (!mounted) return;
            setState(() => _items.insert(index, item));
          },
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unchecked =
        _items.where((item) => !(item['checked'] as bool)).toList();
    final checked = _items.where((item) => item['checked'] as bool).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('shopping')),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _loadItems,
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
                    onPressed: _loadItems,
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

          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),

          // Input Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: _t('add_item_hint'),
                        border: InputBorder.none,
                        prefixIcon: Icon(
                          Icons.shopping_cart_outlined,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      onSubmitted: (_) => _addItem(),
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _addItem,
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

          // To-Buy Section
          if (unchecked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.playlist_add_check,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_t('to_buy')} (${unchecked.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ...unchecked.asMap().entries.map((e) => _buildItem(
                  e.value,
                  theme,
                  e.key,
                )),
            const SizedBox(height: 16),
          ],

          // Checked Section
          if (checked.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.done_all,
                    color: Colors.green[400],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_t('in_cart')} (${checked.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            ...checked.asMap().entries.map((e) => _buildItem(
                  e.value,
                  theme,
                  unchecked.length + e.key,
                )),
          ],

          if (_items.isEmpty) ...[
            const SizedBox(height: 40),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _t('no_items'),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItem(
    Map<String, dynamic> item,
    ThemeData theme,
    int index,
  ) {
    final isChecked = item['checked'] as bool;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: isChecked ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isChecked
              ? BorderSide(color: Colors.grey[300]!, width: 1)
              : BorderSide.none,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: Checkbox(
            value: isChecked,
            onChanged: (val) => _toggleItemChecked(item, val ?? false),
            shape: const RoundedRectangleBorder(),
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
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: () => _deleteItem(index),
          ),
        ),
      ),
    );
  }
}
