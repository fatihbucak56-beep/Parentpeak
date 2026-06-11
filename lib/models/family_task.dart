class FamilyTask {
  final String id;
  final String title;
  final bool done;
  final String assignee;
  final String category;

  const FamilyTask({
    required this.id,
    required this.title,
    required this.done,
    required this.assignee,
    required this.category,
  });

  FamilyTask copyWith({
    String? id,
    String? title,
    bool? done,
    String? assignee,
    String? category,
  }) {
    return FamilyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      done: done ?? this.done,
      assignee: assignee ?? this.assignee,
      category: category ?? this.category,
    );
  }

  factory FamilyTask.fromJson(Map<String, dynamic> json) {
    return FamilyTask(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      done: json['done'] == true,
      assignee: json['assignee']?.toString() ?? 'Familie',
      category: json['category']?.toString() ?? 'Allgemein',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'done': done,
      'assignee': assignee,
      'category': category,
    };
  }
}
