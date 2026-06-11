import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_contract_utils.dart';

class TodoContract {
  static String get todosPath => APIConfig.getBackendTodosPath();

  static String todoByIdPath(String id) {
    final base = todosPath.endsWith('/') ? todosPath.substring(0, todosPath.length - 1) : todosPath;
    return '$base/$id';
  }

  static List<Map<String, dynamic>> parseList(dynamic payload) {
    final raw = extractListFromPayload(payload, const ['items', 'todos', 'data', 'results']);
    return raw.map(normalize).toList();
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    return {
      'id': pickString(raw, const ['id', '_id', 'uuid'], nowId),
      'title': pickString(raw, const ['title', 'name', 'text'], ''),
      'done': pickBool(raw, const ['done', 'completed', 'isDone'], false),
      'assignee': pickString(raw, const ['assignee', 'owner', 'person'], 'Familie'),
      'category': pickString(raw, const ['category', 'type', 'group'], 'Allgemein'),
    };
  }
}
