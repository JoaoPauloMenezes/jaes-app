import 'package:uuid/uuid.dart';

class Flashcard {
  final String id;
  final String frontText;
  final String backText;
  final String? setId; // Reference to a SetOfCards
  final DateTime createdAt;
  final DateTime? updatedAt;

  Flashcard({
    String? id,
    required this.frontText,
    required this.backText,
    this.setId,
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
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Flashcard(
      id: id ?? this.id,
      frontText: frontText ?? this.frontText,
      backText: backText ?? this.backText,
      setId: setId ?? this.setId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Flashcard(id: $id, frontText: $frontText, backText: $backText)';
}
