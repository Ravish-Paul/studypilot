import 'topic.dart';

class Subject {
  final String id;
  String name;
  int colorValue;
  DateTime? examDate;
  int priority;
  List<Topic> topics;

  Subject({
    required this.id,
    required this.name,
    this.colorValue = 0xFF6C7CFF,
    this.examDate,
    this.priority = 2,
    List<Topic>? topics,
  }) : topics = topics ?? [];

  List<Topic> get pendingTopics => topics.where((t) => !t.done).toList();
  int get pendingMinutes =>
      pendingTopics.fold(0, (sum, t) => sum + t.estMinutes);
  int get doneCount => topics.where((t) => t.done).length;
  double get progress =>
      topics.isEmpty ? 0 : doneCount / topics.length;

  int? get daysLeft {
    if (examDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return examDate!.difference(today).inDays;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'examDate': examDate?.toIso8601String(),
        'priority': priority,
        'topics': topics.map((t) => t.toJson()).toList(),
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: (json['colorValue'] as num).toInt(),
        examDate: json['examDate'] == null
            ? null
            : DateTime.parse(json['examDate'] as String),
        priority: (json['priority'] as num?)?.toInt() ?? 2,
        topics: (json['topics'] as List? ?? [])
            .map((t) => Topic.fromJson(Map<String, dynamic>.from(t as Map)))
            .toList(),
      );
}
