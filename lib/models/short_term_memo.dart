/// ShortTermMemo represents the learning progress tracking for a flashcard
/// It stores test history: last test date and whether the user passed
class ShortTermMemo {
  final String flashcardId; // Reference to a Flashcard
  final DateTime lastTestDate;
  final bool passed;

  ShortTermMemo({
    required this.flashcardId,
    required this.lastTestDate,
    required this.passed,
  });

  /// Convert ShortTermMemo to JSON
  Map<String, dynamic> toJson() {
    return {
      'flashcardId': flashcardId,
      'lastTestDate': lastTestDate.toIso8601String(),
      'passed': passed,
    };
  }

  /// Create ShortTermMemo from JSON
  factory ShortTermMemo.fromJson(Map<String, dynamic> json) {
    return ShortTermMemo(
      flashcardId: json['flashcardId'] as String,
      lastTestDate: DateTime.parse(json['lastTestDate'] as String),
      passed: json['passed'] as bool,
    );
  }

  /// Create a copy of ShortTermMemo with optional field replacements
  ShortTermMemo copyWith({
    String? flashcardId,
    DateTime? lastTestDate,
    bool? passed,
  }) {
    return ShortTermMemo(
      flashcardId: flashcardId ?? this.flashcardId,
      lastTestDate: lastTestDate ?? this.lastTestDate,
      passed: passed ?? this.passed,
    );
  }

  @override
  String toString() =>
      'ShortTermMemo(flashcardId: $flashcardId, lastTestDate: $lastTestDate, passed: $passed)';
}
