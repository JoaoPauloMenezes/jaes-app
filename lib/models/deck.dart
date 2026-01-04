import 'package:uuid/uuid.dart';

class Deck {
  final String id;
  String title;
  String description;
  bool isActive;

  Deck({
    String? id,
    required this.title,
    required this.description,
    required this.isActive,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'isActive': isActive,
      };

  factory Deck.fromJson(Map<String, dynamic> json) => Deck(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        isActive: json['isActive'],
      );
}
