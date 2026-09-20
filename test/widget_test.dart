import 'package:flutter_test/flutter_test.dart';

import 'package:studypilot/services/scheduler.dart';
import 'package:studypilot/models/subject.dart';
import 'package:studypilot/models/topic.dart';

void main() {
  test('local scheduler schedules all pending topics', () {
    final subject = Subject(
      id: 's1',
      name: 'DBMS',
      examDate: DateTime.now().add(const Duration(days: 5)),
      topics: [
        Topic(id: 't1', title: 'Normalization', estMinutes: 60),
        Topic(id: 't2', title: 'Indexes', estMinutes: 45),
        Topic(id: 't3', title: 'Joins', estMinutes: 30),
      ],
    );

    final tasks = LocalScheduler().buildPlan(
      subjects: [subject],
      today: DateTime.now(),
      dailyMinutes: 90,
    );

    expect(tasks.length, 3);
    final total = tasks.fold<int>(0, (sum, t) => sum + t.plannedMinutes);
    expect(total, 135);
    final day1 = tasks.where((t) => t.plannedMinutes == 60).length;
    expect(day1, 1);
  });

  test('local scheduler respects daily minutes', () {
    final subject = Subject(
      id: 's1',
      name: 'Math',
      topics: List.generate(
        5,
        (i) => Topic(id: 't$i', title: 'Chapter $i', estMinutes: 60),
      ),
    );

    final tasks = LocalScheduler().buildPlan(
      subjects: [subject],
      today: DateTime.now(),
      dailyMinutes: 120,
    );

    final byDay = <DateTime, int>{};
    for (final task in tasks) {
      byDay[task.date] = (byDay[task.date] ?? 0) + task.plannedMinutes;
    }
    for (final load in byDay.values) {
      expect(load <= 120, isTrue);
    }
    expect(tasks.length, 5);
  });
}
