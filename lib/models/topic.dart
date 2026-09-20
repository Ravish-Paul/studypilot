class Topic {
  final String id;
  String title;
  int estMinutes;
  bool done;
  DateTime? completedAt;

  Topic({
    required this.id,
    required this.title,
    this.estMinutes = 30,
    this.done = false,
    this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'estMinutes': estMinutes,
        'done': done,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Topic.fromJson(Map<String, dynamic> json) => Topic(
        id: json['id'] as String,
        title: json['title'] as String,
        estMinutes: (json['estMinutes'] as num?)?.toInt() ?? 30,
        done: json['done'] as bool? ?? false,
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );

  Topic copyWith({
    String? title,
    int? estMinutes,
    bool? done,
    DateTime? completedAt,
  }) =>
      Topic(
        id: id,
        title: title ?? this.title,
        estMinutes: estMinutes ?? this.estMinutes,
        done: done ?? this.done,
        completedAt: completedAt ?? this.completedAt,
      );
}
