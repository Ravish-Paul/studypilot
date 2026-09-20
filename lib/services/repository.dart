import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/app_state.dart';
import '../models/plan_task.dart';
import '../models/subject.dart';

class Repository {
  static const _subjectsBox = 'subjects';
  static const _planBox = 'plan';
  static const _stateBox = 'state';

  late Box _subjects;
  late Box _plan;
  late Box _state;

  Future<void> init() async {
    _subjects = await Hive.openBox(_subjectsBox);
    _plan = await Hive.openBox(_planBox);
    _state = await Hive.openBox(_stateBox);
  }

  static String dateKey(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  static String newId() =>
      DateTime.now().microsecondsSinceEpoch.toString() +
      (DateTime.now().millisecondsSinceEpoch % 1000).toString();

  List<Subject> loadSubjects() {
    final values = _subjects.values.cast<Map>().toList();
    return values
        .map((s) => Subject.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<void> saveSubject(Subject subject) =>
      _subjects.put(subject.id, subject.toJson());

  Future<void> deleteSubject(String id) async {
    await _subjects.delete(id);
    final keys = _plan.keys.cast<String>().toList();
    for (final key in keys) {
      final tasks = _plan.get(key) as List? ?? [];
      final kept = tasks
          .where(
            (t) => (t as Map)['subjectId'] != id,
          )
          .toList();
      if (kept.isEmpty) {
        await _plan.delete(key);
      } else {
        await _plan.put(key, kept);
      }
    }
  }

  Map<DateTime, List<PlanTask>> loadPlan() {
    final result = <DateTime, List<PlanTask>>{};
    for (final key in _plan.keys.cast<String>()) {
      final raw = _plan.get(key) as List? ?? [];
      final tasks = raw
          .map(
            (t) => PlanTask.fromJson(Map<String, dynamic>.from(t as Map)),
          )
          .toList()
        ..sort((a, b) => a.subjectName.compareTo(b.subjectName));
      final date = DateTime.parse(key);
      result[date] = tasks;
    }
    final sorted = Map.fromEntries(
      result.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
    return sorted;
  }

  Future<void> savePlanDay(DateTime date, List<PlanTask> tasks) =>
      _plan.put(dateKey(date), tasks.map((t) => t.toJson()).toList());

  Future<void> deletePlanDay(DateTime date) => _plan.delete(dateKey(date));

  Future<void> clearPlanFrom(DateTime date) async {
    final keys = _plan.keys.cast<String>().toList();
    for (final key in keys) {
      final keyDate = DateTime.parse(key);
      if (!keyDate.isBefore(DateTime(date.year, date.month, date.day))) {
        await _plan.delete(key);
      }
    }
  }

  Future<void> clearAllPlan() async {
    await _plan.clear();
  }

  AppState loadState() {
    final raw = _state.get('state');
    if (raw == null) return AppState();
    return AppState.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  Future<void> saveState(AppState state) => _state.put('state', state.toJson());

  Future<void> resetAll() async {
    await _subjects.clear();
    await _plan.clear();
    await _state.clear();
  }
}
