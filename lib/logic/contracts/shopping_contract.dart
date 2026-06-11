import 'package:trusted_circle_demo/config/api_config.dart';

import 'backend_contract_utils.dart';

class ShoppingContract {
  static String get shoppingPath => APIConfig.getBackendShoppingPath();

  static String itemByIdPath(String id) {
    final base = shoppingPath.endsWith('/') ? shoppingPath.substring(0, shoppingPath.length - 1) : shoppingPath;
    return '$base/$id';
  }

  static List<Map<String, dynamic>> parseList(dynamic payload) {
    final raw = extractListFromPayload(payload, const ['items', 'shopping', 'data', 'results']);
    return raw.map(normalize).toList();
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final nowId = DateTime.now().microsecondsSinceEpoch.toString();
    return {
      'id': pickString(raw, const ['id', '_id', 'uuid'], nowId),
      'name': pickString(raw, const ['name', 'title', 'label'], ''),
      'checked': pickBool(raw, const ['checked', 'done', 'purchased'], false),
      'category': pickString(raw, const ['category', 'group', 'type'], 'Allgemein'),
    };
  }
}
