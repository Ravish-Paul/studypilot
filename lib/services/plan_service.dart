import '../models/plan_task.dart';
import '../models/subject.dart';
import 'ai_service.dart';
import 'repository.dart';
import 'scheduler.dart';

enum PlanSource { ai, offline }

class PlanGenerationResult {
  final PlanSource source;
  final bool limitReached;
  final String summary;

  PlanGenerationResult({
    required this.source,
    required this.limitReached,
    this.summary = '',
  });
}

class PlanService {
  final Repository repository;
  final AiService aiService;
  final LocalScheduler scheduler = LocalScheduler();

  PlanService({required this.repository, required this.aiService});

  Future<PlanGenerationResult> generatePlan({
    required List<Subject> subjects,
    required int dailyMinutes,
    required bool isPro,
    required int aiGenerationsUsed,
    required int freeAiLimit,
    bool forceOffline = false,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final aiAllowed = aiService.isConfigured &&
        !forceOffline &&
        (isPro || aiGenerationsUsed < freeAiLimit);

    if (aiAllowed) {
      final aiResult = await aiService.generatePlan(
        subjects: subjects,
        today: today,
        dailyMinutes: dailyMinutes,
      );

      if (aiResult != null) {
        final tasks = _coverGaps(aiResult.tasks, subjects, today, dailyMinutes);
        await _persist(tasks, today, ai: true);
        return PlanGenerationResult(
          source: PlanSource.ai,
          limitReached: false,
          summary: aiResult.summary,
        );
      }
    }

    final tasks = scheduler.buildPlan(
      subjects: subjects,
      today: today,
      dailyMinutes: dailyMinutes,
    );
    await _persist(tasks, today, ai: false);

    final limitReached = aiService.isConfigured &&
        !forceOffline &&
        !isPro &&
        aiGenerationsUsed >= freeAiLimit;

    return PlanGenerationResult(
      source: PlanSource.offline,
      limitReached: limitReached,
    );
  }

  List<PlanTask> _coverGaps(
    List<PlanTask> aiTasks,
    List<Subject> subjects,
    DateTime today,
    int dailyMinutes,
  ) {
    final scheduled = aiTasks
        .map((t) => '${t.subjectId}:${t.topicTitle.toLowerCase().trim()}')
        .toSet();

    final leftover = <PlanTask>[];
    for (final subject in subjects) {
      for (final topic in subject.pendingTopics) {
        final key = '${subject.id}:${topic.title.toLowerCase().trim()}';
        if (!scheduled.contains(key)) {
          leftover.add(
            PlanTask(
              id: Repository.newId(),
              date: today.add(const Duration(days: 1)),
              subjectId: subject.id,
              subjectName: subject.name,
              subjectColorValue: subject.colorValue,
              topicTitle: topic.title,
              plannedMinutes: topic.estMinutes,
            ),
          );
        }
      }
    }

    if (leftover.isEmpty) return aiTasks;

    final merged = List<PlanTask>.from(aiTasks);
    final rescheduled = <PlanTask>[];
    for (final task in leftover) {
      var day = DateTime(today.year, today.month, today.day);
      while (true) {
        final dayLoad = merged
                .where((t) => t.date == day)
                .fold(0, (sum, t) => sum + t.plannedMinutes) +
            rescheduled
                .where((t) => t.date == day)
                .fold(0, (sum, t) => sum + t.plannedMinutes);
        if (dayLoad + task.plannedMinutes <= dailyMinutes) break;
        day = day.add(const Duration(days: 1));
      }
      rescheduled.add(
        PlanTask(
          id: Repository.newId(),
          date: day,
          subjectId: task.subjectId,
          subjectName: task.subjectName,
          subjectColorValue: task.subjectColorValue,
          topicTitle: task.topicTitle,
          plannedMinutes: task.plannedMinutes,
        ),
      );
    }
    merged.addAll(rescheduled);
    merged.sort((a, b) => a.date.compareTo(b.date));
    return merged;
  }

  Future<void> _persist(
    List<PlanTask> tasks,
    DateTime today, {
    required bool ai,
  }) async {
    await repository.clearPlanFrom(today);
    final byDay = <DateTime, List<PlanTask>>{};
    for (final task in tasks) {
      byDay.putIfAbsent(task.date, () => []).add(task);
    }
    for (final entry in byDay.entries) {
      await repository.savePlanDay(entry.key, entry.value);
    }
  }
}
