class FamilyShoppingItem {
  final String id;
  final String name;
  final bool checked;
  final String category;

  const FamilyShoppingItem({
    required this.id,
    required this.name,
    required this.checked,
    required this.category,
  });

  FamilyShoppingItem copyWith({
    String? id,
    String? name,
    bool? checked,
    String? category,
  }) {
    return FamilyShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      checked: checked ?? this.checked,
      category: category ?? this.category,
    );
  }

  factory FamilyShoppingItem.fromJson(Map<String, dynamic> json) {
    return FamilyShoppingItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      checked: json['checked'] == true,
      category: json['category']?.toString() ?? 'Allgemein',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'checked': checked,
      'category': category,
    };
  }
}
