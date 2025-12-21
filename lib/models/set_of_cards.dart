import 'package:uuid/uuid.dart';

class SetOfCards {
  final String id;
  String title;
  String description;
  bool isActive;

  SetOfCards({
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

  factory SetOfCards.fromJson(Map<String, dynamic> json) => SetOfCards(
        id: json['id'],
        title: json['title'],
        description: json['description'],
        isActive: json['isActive'],
      );
}