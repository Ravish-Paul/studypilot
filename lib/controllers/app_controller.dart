import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../models/plan_task.dart';
import '../models/subject.dart';
import '../models/topic.dart';
import '../services/ai_service.dart';
import '../services/plan_service.dart';
import '../services/repository.dart';

enum SubjectLimitResult { ok, limitReached }

class AppController extends ChangeNotifier {
  final Repository repository;
  final AiService aiService;
  late final PlanService planService;

  List<Subject> subjects = [];
  Map<DateTime, List<PlanTask>> plan = {};
  AppState state = AppState();

  bool generatingPlan = false;

  AppController({required this.repository, required this.aiService}) {
    planService = PlanService(repository: repository, aiService: aiService);
    _loadAll();
  }

  void _loadAll() {
    subjects = repository.loadSubjects();
    plan = repository.loadPlan();
    state = repository.loadState();
  }

  List<PlanTask> tasksFor(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    return plan[target] ?? [];
  }

  List<PlanTask> get todayTasks {
    final now = DateTime.now();
    return tasksFor(DateTime(now.year, now.month, now.day));
  }

  List<MapEntry<DateTime, List<PlanTask>>> get upcomingDays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return plan.entries
        .where((e) => !e.key.isBefore(today))
        .toList();
  }

  List<Subject> get subjectsWithExams =>
      subjects.where((s) => s.examDate != null).toList()
        ..sort((a, b) => a.examDate!.compareTo(b.examDate!));

  bool get hasAnyPlan => plan.values.any((tasks) => tasks.isNotEmpty);

  int get aiPlansLeft {
    if (state.isPro) return -1;
    final left = state.freeAiLimit - state.aiGenerationsUsed;
    return left > 0 ? left : 0;
  }

  Future<SubjectLimitResult> addSubject(
    String name, {
    DateTime? examDate,
    int priority = 2,
    int colorValue = 0xFF6C7CFF,
  }) async {
    if (!state.isPro && subjects.isNotEmpty) {
      return SubjectLimitResult.limitReached;
    }
    final subject = Subject(
      id: Repository.newId(),
      name: name,
      examDate: examDate,
      priority: priority,
      colorValue: colorValue,
    );
    subjects.add(subject);
    await repository.saveSubject(subject);
    notifyListeners();
    return SubjectLimitResult.ok;
  }

  Future<void> updateSubject(
    Subject subject, {
    String? name,
    DateTime? examDate,
    int? priority,
  }) async {
    if (name != null && name.trim().isNotEmpty) subject.name = name.trim();
    if (examDate != null) subject.examDate = examDate;
    if (priority != null) subject.priority = priority;
    await repository.saveSubject(subject);
    notifyListeners();
  }

  Future<void> deleteSubject(Subject subject) async {
    subjects.removeWhere((s) => s.id == subject.id);
    await repository.deleteSubject(subject.id);
    plan = repository.loadPlan();
    notifyListeners();
  }

  Future<void> addTopic(String subjectId, String title, int estMinutes) async {
    final subject = subjects.firstWhere((s) => s.id == subjectId);
    subject.topics.add(
      Topic(
        id: Repository.newId(),
        title: title.trim(),
        estMinutes: estMinutes,
      ),
    );
    await repository.saveSubject(subject);
    notifyListeners();
  }

  Future<void> setTopicDone(Subject subject, Topic topic, bool done) async {
    topic.done = done;
    topic.completedAt = done ? DateTime.now() : null;
    await repository.saveSubject(subject);
    notifyListeners();
  }

  Future<void> deleteTopic(Subject subject, Topic topic) async {
    subject.topics.removeWhere((t) => t.id == topic.id);
    await repository.saveSubject(subject);
    notifyListeners();
  }

  Future<void> setDailyGoal(int minutes) async {
    state.dailyMinutesGoal = minutes;
    await repository.saveState(state);
    notifyListeners();
  }

  Future<PlanGenerationResult> generatePlan({bool forceOffline = false}) async {
    generatingPlan = true;
    notifyListeners();

    try {
      final result = await planService.generatePlan(
        subjects: subjects,
        dailyMinutes: state.dailyMinutesGoal,
        isPro: state.isPro,
        aiGenerationsUsed: state.aiGenerationsUsed,
        freeAiLimit: state.freeAiLimit,
        forceOffline: forceOffline,
      );

      if (result.source == PlanSource.ai) {
        state.aiGenerationsUsed += 1;
      }
      state.lastPlanWasAi = result.source == PlanSource.ai;
      state.lastPlanAt = DateTime.now();
      state.onboarded = true;
      await repository.saveState(state);
      plan = repository.loadPlan();
      notifyListeners();
      return result;
    } finally {
      generatingPlan = false;
      notifyListeners();
    }
  }

  Future<void> setTaskStatus(PlanTask task, TaskStatus status) async {
    final day = DateTime(task.date.year, task.date.month, task.date.day);
    final tasks = plan[day];
    if (tasks == null) return;

    final index = tasks.indexWhere((t) => t.id == task.id);
    if (index == -1) return;

    tasks[index] = tasks[index].copyWith(status: status);
    await repository.savePlanDay(day, tasks);

    if (status == TaskStatus.done) {
      _completeTopicForTask(task);
      _touchStreak();
    }

    notifyListeners();
  }

  void _completeTopicForTask(PlanTask task) {
    final subject = subjects.where((s) => s.id == task.subjectId).toList();
    if (subject.isEmpty) return;
    final target = subject.first;
    final topic = target.pendingTopics
        .where((t) => t.title.toLowerCase().trim() == task.topicTitle.toLowerCase().trim())
        .toList();
    if (topic.isEmpty) return;
    topic.first.done = true;
    topic.first.completedAt = DateTime.now();
    repository.saveSubject(target);
  }

  void _touchStreak() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final last = state.lastStudyDate;

    if (last == null || last.isBefore(today.subtract(const Duration(days: 1)))) {
      state.streakDays = 1;
    } else if (last.isBefore(today)) {
      state.streakDays += 1;
    } else {
      return;
    }
    state.lastStudyDate = today;
    repository.saveState(state);
  }

  Future<void> logStudyMinutes(int minutes) async {
    state.totalStudyMinutes += minutes;
    await repository.saveState(state);
    notifyListeners();
  }

  Future<void> setPro(bool value) async {
    state.isPro = value;
    await repository.saveState(state);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await repository.resetAll();
    _loadAll();
    notifyListeners();
  }
}
