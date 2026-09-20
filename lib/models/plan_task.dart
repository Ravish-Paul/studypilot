enum TaskStatus { todo, done, skipped }

class PlanTask {
  final String id;
  final DateTime date;
  final String subjectId;
  final String subjectName;
  final int subjectColorValue;
  final String topicTitle;
  final int plannedMinutes;
  TaskStatus status;

  PlanTask({
    required this.id,
    required this.date,
    required this.subjectId,
    required this.subjectName,
    required this.subjectColorValue,
    required this.topicTitle,
    required this.plannedMinutes,
    this.status = TaskStatus.todo,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'subjectId': subjectId,
        'subjectName': subjectName,
        'subjectColorValue': subjectColorValue,
        'topicTitle': topicTitle,
        'plannedMinutes': plannedMinutes,
        'status': status.name,
      };

  factory PlanTask.fromJson(Map<String, dynamic> json) => PlanTask(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        subjectId: json['subjectId'] as String,
        subjectName: json['subjectName'] as String,
        subjectColorValue: (json['subjectColorValue'] as num).toInt(),
        topicTitle: json['topicTitle'] as String,
        plannedMinutes: (json['plannedMinutes'] as num?)?.toInt() ?? 30,
        status: TaskStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => TaskStatus.todo,
        ),
      );

  PlanTask copyWith({TaskStatus? status}) => PlanTask(
        id: id,
        date: date,
        subjectId: subjectId,
        subjectName: subjectName,
        subjectColorValue: subjectColorValue,
        topicTitle: topicTitle,
        plannedMinutes: plannedMinutes,
        status: status ?? this.status,
      );
}
