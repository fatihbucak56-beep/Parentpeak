enum ExpenseCategory {
  groceries,
  baby,
  deposit,
  transport,
  health,
  leisure,
  personal,
  housing,
  other,
}

enum ExpenseSplitType {
  standardSplit,
  individual,
  intelligentOcrSplit,
}

class Expense {
  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.paidById,
    required this.category,
    required this.splitType,
    this.customSplitByParent,
    this.sourceReceiptId,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String paidById;
  final ExpenseCategory category;
  final ExpenseSplitType splitType;
  final Map<String, double>? customSplitByParent;
  final String? sourceReceiptId;

  Expense copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? date,
    String? paidById,
    ExpenseCategory? category,
    ExpenseSplitType? splitType,
    Map<String, double>? customSplitByParent,
    bool clearCustomSplitByParent = false,
    String? sourceReceiptId,
    bool clearSourceReceiptId = false,
  }) {
    return Expense(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      paidById: paidById ?? this.paidById,
      category: category ?? this.category,
      splitType: splitType ?? this.splitType,
      customSplitByParent: clearCustomSplitByParent
          ? null
          : customSplitByParent ?? this.customSplitByParent,
      sourceReceiptId:
          clearSourceReceiptId ? null : sourceReceiptId ?? this.sourceReceiptId,
    );
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    final rawCustomSplit = map['customSplitByParent'];
    final parsedSplit = <String, double>{};

    if (rawCustomSplit is Map) {
      for (final entry in rawCustomSplit.entries) {
        final parentId = entry.key.toString();
        final value = entry.value;
        if (value is num) {
          parsedSplit[parentId] = value.toDouble();
        }
      }
    }

    return Expense(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      paidById: map['paidById']?.toString() ?? '',
      category: ExpenseCategory.values.firstWhere(
        (item) => item.name == map['category']?.toString(),
        orElse: () => ExpenseCategory.other,
      ),
      splitType: ExpenseSplitType.values.firstWhere(
        (item) => item.name == map['splitType']?.toString(),
        orElse: () => ExpenseSplitType.standardSplit,
      ),
      customSplitByParent: parsedSplit.isEmpty ? null : parsedSplit,
      sourceReceiptId: map['sourceReceiptId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'paidById': paidById,
      'category': category.name,
      'splitType': splitType.name,
      'customSplitByParent': customSplitByParent,
      'sourceReceiptId': sourceReceiptId,
    };
  }
}
