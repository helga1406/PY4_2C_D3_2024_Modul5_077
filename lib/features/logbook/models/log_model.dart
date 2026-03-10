import 'package:hive/hive.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

part 'log_model.g.dart'; 

@HiveType(typeId: 0)
class LogModel extends HiveObject {
  @HiveField(0)
  final String? id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String date;

  @HiveField(4)
  final String authorId;

  @HiveField(5)
  final String teamId;

  @HiveField(6)
  final String category; 

  LogModel({
    this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.authorId,
    required this.teamId,
    required this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      '_id': (id == null || id!.contains('temp')) 
          ? ObjectId() 
          : ObjectId.fromHexString(id!),
      'title': title,
      'description': description,
      'date': date,
      'authorId': authorId,
      'teamId': teamId,
      'category': category, 
    };
  }

  factory LogModel.fromMap(Map<String, dynamic> map) {
    return LogModel(
      id: (map['_id'] as ObjectId?)?.oid,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      date: map['date'] ?? '',
      authorId: map['authorId'] ?? 'unknown_user',
      teamId: map['teamId'] ?? 'no_team',
      category: map['category'] ?? 'Pribadi', 
    );
  }
}