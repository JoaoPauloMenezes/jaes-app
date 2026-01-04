import 'package:uuid/uuid.dart';
import '../enums/flashcard_state.dart';

class Flashcard {
  final String id;
  final String frontText;
  final String backText;
  final String? setId; // Reference to a SetOfCards
  final bool isEnabled;
  final FlashcardState state;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Flashcard({
    String? id,
    required this.frontText,
    required this.backText,
    this.setId,
    this.isEnabled = true,
    this.state = FlashcardState.toLearn,
    DateTime? createdAt,
    this.updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  /// Convert Flashcard to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frontText': frontText,
      'backText': backText,
      'setId': setId,
      'isEnabled': isEnabled,
      'state': state.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Create Flashcard from JSON
  factory Flashcard.fromJson(Map<String, dynamic> json) {
    return Flashcard(
      id: json['id'] as String,
      frontText: json['frontText'] as String,
      backText: json['backText'] as String,
      setId: json['setId'] as String?,
      isEnabled: json['isEnabled'] == null ? true : json['isEnabled'] as bool,
      state: json['state'] != null ? FlashcardState.fromString(json['state'] as String) : FlashcardState.toLearn,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Create a copy of Flashcard with optional field replacements
  Flashcard copyWith({
    String? id,
    String? frontText,
    String? backText,
    String? setId,
    bool? isEnabled,
    FlashcardState? state,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      setId: setId ?? this.setId,
      isEnabled: isEnabled ?? this.isEnabled,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Flashcard(id: $id, frontText: $frontText, backText: $backText, isEnabled: $isEnabled)';
}
