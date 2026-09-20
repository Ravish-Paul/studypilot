import '../models/plan_task.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import 'repository.dart';

class LocalScheduler {
  static const int _minMinutes = 10;

  List<PlanTask> buildPlan({
    required List<Subject> subjects,
    required DateTime today,
    required int dailyMinutes,
  }) {
    final tasks = <PlanTask>[];
    var day = DateTime(today.year, today.month, today.day);
    var remaining = dailyMinutes;

    final active = subjects
        .where((s) => s.pendingTopics.isNotEmpty)
        .toList()
      ..sort((a, b) => _urgency(a, today).compareTo(_urgency(b, today)));

    if (active.isEmpty) return tasks;

    final queues = active
        .map((s) => _SubjectQueue(s, s.pendingTopics.toList()))
        .toList();

    while (queues.any((q) => q.topics.isNotEmpty)) {
      var placedAny = false;

      for (final queue in queues) {
        if (queue.topics.isEmpty) continue;

        final topic = queue.topics.first;
        var minutes = topic.estMinutes;
        if (minutes < _minMinutes) minutes = _minMinutes;
        if (minutes > dailyMinutes) minutes = dailyMinutes;

        if (minutes > remaining) continue;

        queue.topics.removeAt(0);
        tasks.add(
          PlanTask(
            id: Repository.newId(),
            date: day,
            subjectId: queue.subject.id,
            subjectName: queue.subject.name,
            subjectColorValue: queue.subject.colorValue,
            topicTitle: topic.title,
            plannedMinutes: minutes,
          ),
        );
        remaining -= minutes;
        placedAny = true;

        if (remaining == 0) break;
      }

      final dayFull = remaining == 0;
      if (!placedAny || dayFull) {
        day = day.add(const Duration(days: 1));
        remaining = dailyMinutes;
      }
    }

    tasks.sort((a, b) => a.date.compareTo(b.date));
    return tasks;
  }

  int _urgency(Subject subject, DateTime today) {
    final daysLeft = subject.daysLeft;
    final examScore = daysLeft ?? 999;
    return examScore * 10 + subject.priority;
  }
}

class _SubjectQueue {
  final Subject subject;
  final List<Topic> topics;

  _SubjectQueue(this.subject, this.topics);
}
