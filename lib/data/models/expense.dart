/// A single farm expense: seeds, fertilizer, labor, etc.
class Expense {
  Expense({
    required this.id,
    required this.cropId,
    required this.amount,
    required this.category,
    required this.date,
    this.description = '',
  });

  final String id;
  final String cropId; // can be empty for general farm expenses
  final double amount;
  final String
  category; // seeds | fertilizer | pesticide | labor | equipment | other
  final DateTime date;
  String description;

  Map<String, dynamic> toMap() => {
    'id': id,
    'cropId': cropId,
    'amount': amount,
    'category': category,
    'date': date.toIso8601String(),
    'description': description,
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: m['id'] as String,
    cropId: m['cropId'] as String,
    amount: (m['amount'] as num).toDouble(),
    category: m['category'] as String,
    date: DateTime.parse(m['date'] as String),
    description: (m['description'] ?? '') as String,
  );
}

/// Stored in the `users/{uid}/expenses/{expenseId}` Firestore
/// collection. No local cache.
