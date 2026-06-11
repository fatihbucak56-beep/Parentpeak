import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/config/api_config.dart';
import 'package:trusted_circle_demo/logic/backend_service_factory.dart';

class BackendStatusScreen extends StatefulWidget {
  const BackendStatusScreen({super.key});

  @override
  State<BackendStatusScreen> createState() => _BackendStatusScreenState();
}

class _BackendStatusScreenState extends State<BackendStatusScreen> {
  bool _loading = true;
  List<_EndpointCheck> _checks = [];
  String? _baseUrl;
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _runChecks();
  }

  Future<void> _runChecks() async {
    setState(() {
      _loading = true;
      _checks = [];
      _baseUrl = APIConfig.getBackendBaseUrl();
      _hasToken = (APIConfig.getBackendApiToken() ?? '').isNotEmpty;
    });

    final apiClient = BackendServiceFactory.createApiClient();
    if (apiClient == null) {
      setState(() {
        _loading = false;
      });
      return;
    }

    final checks = <_EndpointCheck>[];

    final endpoints = <Map<String, String>>[
      {'label': 'Todos', 'path': APIConfig.getBackendTodosPath()},
      {'label': 'Shopping', 'path': APIConfig.getBackendShoppingPath()},
      {'label': 'Kalender', 'path': APIConfig.getBackendCalendarEventsPath()},
    ];

    for (final endpoint in endpoints) {
      final label = endpoint['label']!;
      final path = endpoint['path']!;
      try {
        final payload = await apiClient.getJson(path);
        final shape = _payloadShape(payload);
        checks.add(_EndpointCheck(
          label: label,
          path: path,
          ok: true,
          detail: 'Erreichbar ($shape)',
        ));
      } catch (e) {
        checks.add(_EndpointCheck(
          label: label,
          path: path,
          ok: false,
          detail: e.toString(),
        ));
      }
    }

    if (!mounted) return;
    setState(() {
      _checks = checks;
      _loading = false;
    });
  }

  String _payloadShape(dynamic payload) {
    if (payload is List) return 'Liste';
    if (payload is Map) {
      final keys = payload.keys.take(4).join(', ');
      return keys.isEmpty ? 'Objekt' : 'Objekt: $keys';
    }
    return payload.runtimeType.toString();
  }

  String _tokenState() {
    return _hasToken ? 'gesetzt' : 'fehlt';
  }

  Color _summaryColor(ThemeData theme) {
    if (_checks.isEmpty) return theme.colorScheme.primary;
    final hasFailure = _checks.any((c) => !c.ok);
    return hasFailure ? theme.colorScheme.error : Colors.green[700]!;
  }

  String _summaryText() {
    if (_checks.isEmpty) {
      if ((_baseUrl ?? '').isEmpty) {
        return 'BACKEND_BASE_URL ist nicht gesetzt.';
      }
      return 'Noch keine Prüfungen ausgeführt.';
    }

    final success = _checks.where((c) => c.ok).length;
    return '$success/${_checks.length} Endpunkte erreichbar';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backend Status'),
        actions: [
          IconButton(
            onPressed: _runChecks,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Neu pruefen',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konfiguration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _kv('Base URL', (_baseUrl ?? '').isEmpty ? 'nicht gesetzt' : _baseUrl!),
                  const SizedBox(height: 8),
                  _kv('API Token', _tokenState()),
                  const SizedBox(height: 8),
                  _kv('Family ID', APIConfig.getBackendFamilyId()),
                  const SizedBox(height: 8),
                  _kv('Schema Version', APIConfig.getBackendApiVersion()),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            color: _summaryColor(theme).withOpacity(0.1),
            child: ListTile(
              leading: Icon(Icons.cloud_done_rounded, color: _summaryColor(theme)),
              title: Text(
                _summaryText(),
                style: TextStyle(
                  color: _summaryColor(theme),
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: const Text('Pruefung gegen konfigurierte Endpunkte'),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            ),
          ..._checks.map((check) {
            final color = check.ok ? Colors.green[700]! : theme.colorScheme.error;
            return Card(
              child: ListTile(
                leading: Icon(
                  check.ok ? Icons.check_circle_rounded : Icons.error_rounded,
                  color: color,
                ),
                title: Text(check.label),
                subtitle: Text('${check.path}\n${check.detail}'),
                isThreeLine: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _kv(String key, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            key,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }
}

class _EndpointCheck {
  final String label;
  final String path;
  final bool ok;
  final String detail;

  const _EndpointCheck({
    required this.label,
    required this.path,
    required this.ok,
    required this.detail,
  });
}
