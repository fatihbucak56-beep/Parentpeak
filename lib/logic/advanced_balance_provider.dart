import 'package:flutter/material.dart';
import 'package:trusted_circle_demo/models/care_activity.dart';
import 'package:trusted_circle_demo/models/expense.dart';

class SavingsOpportunity {
  const SavingsOpportunity({
    required this.id,
    required this.goal,
    required this.retailPrice,
    required this.secondHandPrice,
    required this.distanceKm,
    required this.marketplace,
  });

  final String id;
  final String goal;
  final double retailPrice;
  final double secondHandPrice;
  final double distanceKm;
  final String marketplace;

  double get savings => retailPrice - secondHandPrice;

  factory SavingsOpportunity.fromMap(Map<String, dynamic> map) {
    return SavingsOpportunity(
      id: map['id']?.toString() ?? '',
      goal: map['goal']?.toString() ?? '',
      retailPrice: (map['retailPrice'] as num?)?.toDouble() ?? 0,
      secondHandPrice: (map['secondHandPrice'] as num?)?.toDouble() ?? 0,
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0,
      marketplace: map['marketplace']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal': goal,
      'retailPrice': retailPrice,
      'secondHandPrice': secondHandPrice,
      'distanceKm': distanceKm,
      'marketplace': marketplace,
    };
  }
}

class AdvancedBalanceProvider extends ChangeNotifier {
  AdvancedBalanceProvider({
    required Map<String, double> defaultSplitByParent,
    required List<String> parentIds,
  })  : _defaultSplitByParent = Map<String, double>.from(defaultSplitByParent),
        _parentIds = List<String>.from(parentIds);

  final Map<String, double> _defaultSplitByParent;
  final List<String> _parentIds;

  final List<Expense> _expenses = [];
  final List<CareActivity> _careActivities = [];
  final List<SavingsOpportunity> _opportunities = [];
    DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  List<Expense> get expenses => List<Expense>.unmodifiable(_expenses);
  List<CareActivity> get careActivities => List<CareActivity>.unmodifiable(_careActivities);
  List<SavingsOpportunity> get opportunities =>
      List<SavingsOpportunity>.unmodifiable(_opportunities);

    DateTime get selectedMonth => _selectedMonth;

    void setSelectedMonth(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month, 1);
    notifyListeners();
    }

    List<Expense> get filteredExpenses => _expenses.where((item) {
      return item.date.year == _selectedMonth.year &&
        item.date.month == _selectedMonth.month;
      }).toList();

    List<CareActivity> get filteredCareActivities => _careActivities.where((item) {
      return item.date.year == _selectedMonth.year &&
        item.date.month == _selectedMonth.month;
      }).toList();

    List<SavingsOpportunity> get filteredOpportunities {
    return List<SavingsOpportunity>.from(_opportunities);
    }

  double get monthlyTotalExpenses =>
      filteredExpenses.fold(0, (sum, item) => sum + item.amount);

    double get monthlyNetHouseholdExpenses => filteredExpenses
      .where((item) => item.category != ExpenseCategory.deposit)
      .fold(0, (sum, item) => sum + item.amount);

  double get monthlyCareCredits =>
      filteredCareActivities.fold(0, (sum, item) => sum + item.financialCreditValue);

  double get secondHandSavingsPotential =>
      filteredOpportunities.fold(0, (sum, item) => sum + item.savings);

  Map<String, double> get careCreditsByParent {
    final values = <String, double>{for (final id in _parentIds) id: 0};
    for (final item in filteredCareActivities) {
      values.update(item.parentId, (old) => old + item.financialCreditValue,
          ifAbsent: () => item.financialCreditValue);
    }
    return values;
  }

  Map<String, double> get actualPaidByParent {
    final values = <String, double>{for (final id in _parentIds) id: 0};
    for (final item in filteredExpenses) {
      values.update(item.paidById, (old) => old + item.amount,
          ifAbsent: () => item.amount);
    }
    return values;
  }

  Map<String, double> get expectedShareByParent {
    final values = <String, double>{for (final id in _parentIds) id: 0};

    for (final item in filteredExpenses) {
      final split = _resolveSplit(item);
      for (final entry in split.entries) {
        values.update(entry.key, (old) => old + item.amount * entry.value,
            ifAbsent: () => item.amount * entry.value);
      }
    }

    return values;
  }

  Map<String, double> get finalSettlementByParent {
    final paid = actualPaidByParent;
    final expected = expectedShareByParent;
    final care = careCreditsByParent;

    final result = <String, double>{};
    for (final parent in _parentIds) {
      final net = (paid[parent] ?? 0) - (expected[parent] ?? 0) + (care[parent] ?? 0);
      result[parent] = net;
    }
    return result;
  }

  void addExpense(Expense expense) {
    _expenses.insert(0, expense);
    notifyListeners();
  }

  void addExpenses(List<Expense> expenses) {
    if (expenses.isEmpty) return;
    _expenses.insertAll(0, expenses);
    notifyListeners();
  }

  void updateExpense(Expense expense) {
    final index = _expenses.indexWhere((item) => item.id == expense.id);
    if (index < 0) return;
    _expenses[index] = expense;
    notifyListeners();
  }

  void removeExpense(String expenseId) {
    _expenses.removeWhere((item) => item.id == expenseId);
    notifyListeners();
  }

  void addCareActivity(CareActivity activity) {
    _careActivities.insert(0, activity);
    notifyListeners();
  }

  void updateCareActivity(CareActivity activity) {
    final index = _careActivities.indexWhere((item) => item.id == activity.id);
    if (index < 0) return;
    _careActivities[index] = activity;
    notifyListeners();
  }

  void removeCareActivity(String activityId) {
    _careActivities.removeWhere((item) => item.id == activityId);
    notifyListeners();
  }

  void addSavingsOpportunity(SavingsOpportunity item) {
    _opportunities.insert(0, item);
    notifyListeners();
  }

  void applySnapshot({
    required List<Expense> expenses,
    required List<CareActivity> careActivities,
    required List<SavingsOpportunity> opportunities,
    bool notify = true,
  }) {
    _expenses
      ..clear()
      ..addAll(expenses);
    _careActivities
      ..clear()
      ..addAll(careActivities);
    _opportunities
      ..clear()
      ..addAll(opportunities);

    if (notify) {
      notifyListeners();
    }
  }

  List<Expense> mockImportReceipt({
    required String receiptId,
    required String paidById,
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();

    final items = <Expense>[
      Expense(
        id: '$receiptId-1',
        title: 'Windeln Maxi Pack',
        amount: 24.99,
        date: d,
        paidById: paidById,
        category: ExpenseCategory.baby,
        splitType: ExpenseSplitType.standardSplit,
        sourceReceiptId: receiptId,
      ),
      Expense(
        id: '$receiptId-2',
        title: 'Babybrei',
        amount: 8.49,
        date: d,
        paidById: paidById,
        category: ExpenseCategory.baby,
        splitType: ExpenseSplitType.standardSplit,
        sourceReceiptId: receiptId,
      ),
      Expense(
        id: '$receiptId-3',
        title: 'Rasierklingen',
        amount: 14.99,
        date: d,
        paidById: paidById,
        category: ExpenseCategory.personal,
        splitType: ExpenseSplitType.individual,
        customSplitByParent: {paidById: 1},
        sourceReceiptId: receiptId,
      ),
      Expense(
        id: '$receiptId-4',
        title: 'Familien-Lebensmittel',
        amount: 42.20,
        date: d,
        paidById: paidById,
        category: ExpenseCategory.groceries,
        splitType: ExpenseSplitType.intelligentOcrSplit,
        customSplitByParent: _defaultSplitByParent,
        sourceReceiptId: receiptId,
      ),
    ];

    _expenses.insertAll(0, items);
    notifyListeners();
    return items;
  }

  SavingsOpportunity mockSecondHandDetection({required String goal}) {
    final suggestion = SavingsOpportunity(
      id: 'deal-${DateTime.now().millisecondsSinceEpoch}',
      goal: goal,
      retailPrice: 150,
      secondHandPrice: 40,
      distanceKm: 3.0,
      marketplace: 'Kleinanzeigen',
    );

    addSavingsOpportunity(suggestion);
    return suggestion;
  }

  Map<String, double> _resolveSplit(Expense item) {
    switch (item.splitType) {
      case ExpenseSplitType.standardSplit:
        return _normalizeSplit(_defaultSplitByParent);
      case ExpenseSplitType.individual:
        if (item.customSplitByParent != null && item.customSplitByParent!.isNotEmpty) {
          return _normalizeSplit(item.customSplitByParent!);
        }
        return {item.paidById: 1};
      case ExpenseSplitType.intelligentOcrSplit:
        if (item.customSplitByParent != null && item.customSplitByParent!.isNotEmpty) {
          return _normalizeSplit(item.customSplitByParent!);
        }
        return _normalizeSplit(_defaultSplitByParent);
    }
  }

  Map<String, double> _normalizeSplit(Map<String, double> split) {
    final total = split.values.fold(0.0, (sum, value) => sum + value);
    if (total <= 0) return {for (final parent in _parentIds) parent: 0};

    final normalized = <String, double>{};
    for (final entry in split.entries) {
      normalized[entry.key] = entry.value / total;
    }
    return normalized;
  }
}
