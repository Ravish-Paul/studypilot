import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/plan_task.dart';
import '../models/subject.dart';
import 'repository.dart';

class AiPlanResult {
  final List<PlanTask> tasks;
  final String summary;

  AiPlanResult({required this.tasks, required this.summary});
}

class AiService {
  final String? apiKey;
  final String model;
  final String _endpoint = 'https://openrouter.ai/api/v1/chat/completions';

  AiService({this.apiKey, this.model = 'openai/gpt-4o-mini'});

  bool get isConfigured => apiKey != null && apiKey!.trim().isNotEmpty;

  Future<AiPlanResult?> generatePlan({
    required List<Subject> subjects,
    required DateTime today,
    required int dailyMinutes,
  }) async {
    if (!isConfigured) return null;

    final pendingSubjects = subjects
        .where((s) => s.pendingTopics.isNotEmpty)
        .toList();
    if (pendingSubjects.isEmpty) return null;

    final input = {
      'today': _dayKey(today),
      'dailyMinutes': dailyMinutes,
      'subjects': pendingSubjects
          .map(
            (s) => {
              'name': s.name,
              'examDate': s.examDate == null ? null : _dayKey(s.examDate!),
              'priority': s.priority,
              'topics': s.pendingTopics
                  .map((t) => {'title': t.title, 'estMinutes': t.estMinutes})
                  .toList(),
            },
          )
          .toList(),
    };

    final systemPrompt = '''
You are a study planning engine for students. You receive JSON with today's date, dailyMinutes, and subjects (each with examDate, priority where 1=highest, and topics with estimated minutes).

Create a realistic day-by-day study plan that schedules every pending topic.

Rules:
- The subject with the nearest examDate gets scheduled first and most often.
- Never exceed dailyMinutes in a single day.
- Spread subjects across days; only focus on a single subject if its exam is very near.
- Keep each topic on a single day and use its estimated minutes.
- The plan must start today and cover every pending topic exactly once.
- Output STRICT JSON only. No markdown fences, no commentary.

Schema:
{"startDate":"YYYY-MM-DD","days":[{"date":"YYYY-MM-DD","tasks":[{"subject":"<name>","topic":"<title>","minutes":<int>}]}],"summary":"one short sentence"}
''';

    try {
      final content = await _chat(
        system: systemPrompt,
        user: jsonEncode(input),
      );
      var parsed = _tryParsePlan(content, pendingSubjects, today, dailyMinutes);
      if (parsed == null) {
        final repaired = await _chat(
          system:
              'You return ONLY valid minified JSON. Fix the JSON below so it '
              'matches the schema exactly. No fences, no commentary.',
          user: content,
        );
        parsed = _tryParsePlan(
          repaired,
          pendingSubjects,
          today,
          dailyMinutes,
        );
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  Future<String> _chat({required String system, required String user}) async {
    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {
            'Authorization': 'Bearer ${apiKey!.trim()}',
            'Content-Type': 'application/json',
            'HTTP-Referer': 'https://github.com/studypilot',
            'X-Title': 'StudyPilot',
          },
          body: jsonEncode({
            'model': model,
            'temperature': 0.2,
            'messages': [
              {'role': 'system', 'content': system},
              {'role': 'user', 'content': user},
            ],
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw Exception('OpenRouter error ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = body['choices'] as List? ?? [];
    if (choices.isEmpty) throw Exception('Empty completion');
    final message = (choices.first as Map)['message'] as Map?;
    return (message?['content'] ?? '') as String;
  }

  AiPlanResult? _tryParsePlan(
    String raw,
    List<Subject> subjects,
    DateTime today,
    int dailyMinutes,
  ) {
    try {
      final jsonStr = _extractJson(raw);
      if (jsonStr == null) return null;
      final data = jsonDecode(jsonStr);
      if (data is! Map<String, dynamic>) return null;

      final days = data['days'] as List? ?? [];
      if (days.isEmpty) return null;

      final subjectByName = <String, Subject>{
        for (final s in subjects) s.name.toLowerCase().trim(): s,
      };
      final tasks = <PlanTask>[];
      final startToday = DateTime(today.year, today.month, today.day);
      final maxDate = startToday.add(const Duration(days: 60));

      for (final dayEntry in days) {
        final dayMap = dayEntry as Map<String, dynamic>;
        final date = DateTime.tryParse(dayMap['date']?.toString() ?? '');
        if (date == null) continue;
        final day = DateTime(date.year, date.month, date.day);
        if (day.isBefore(startToday) || day.isAfter(maxDate)) continue;

        for (final taskEntry in dayMap['tasks'] as List? ?? []) {
          final taskMap = taskEntry as Map<String, dynamic>;
          final subject =
              subjectByName[taskMap['subject']?.toString().toLowerCase().trim()];
          if (subject == null) continue;

          var minutes = (taskMap['minutes'] as num?)?.toInt() ?? 0;
          if (minutes <= 0) minutes = 30;
          if (minutes > dailyMinutes) minutes = dailyMinutes;

          tasks.add(
            PlanTask(
              id: Repository.newId(),
              date: day,
              subjectId: subject.id,
              subjectName: subject.name,
              subjectColorValue: subject.colorValue,
              topicTitle: taskMap['topic']?.toString() ?? 'Revision',
              plannedMinutes: minutes,
            ),
          );
        }
      }

      if (tasks.isEmpty) return null;
      return AiPlanResult(
        tasks: tasks,
        summary: data['summary']?.toString() ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  String? _extractJson(String raw) {
    var text = raw.trim();
    if (text.startsWith('```')) {
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
    }
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) return null;
    return text.substring(start, end + 1);
  }

  String _dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}
