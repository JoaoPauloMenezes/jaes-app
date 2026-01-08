/// DailyFlashcardSet represents a set of flashcards selected for a specific day
/// It contains a date and a list of flashcard IDs that should be studied that day
class DailyFlashcardSet {
  final DateTime date;
  final List<String> flashcardIds;

  DailyFlashcardSet({
    required this.date,
    required this.flashcardIds,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'flashcardIds': flashcardIds,
    };
  }

  /// Create from JSON
  factory DailyFlashcardSet.fromJson(Map<String, dynamic> json) {
    return DailyFlashcardSet(
      date: DateTime.parse(json['date'] as String),
      flashcardIds: List<String>.from(json['flashcardIds'] as List),
    );
  }

  /// Check if this set is from today
  bool isFromToday() {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  String toString() =>
      'DailyFlashcardSet(date: $date, count: ${flashcardIds.length})';
}
