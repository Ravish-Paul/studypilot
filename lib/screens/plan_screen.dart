import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/plan_task.dart';
import '../providers.dart';
import 'root_shell.dart' show regeneratePlan;

class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final days = app.upcomingDays;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your plan',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.tonalIcon(
              onPressed: app.generatingPlan ? null : () => regeneratePlan(context, ref),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Adapt'),
            ),
          ),
        ],
      ),
      body: days.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_note,
                    size: 64,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  const Text('No plan yet'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => regeneratePlan(context, ref),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Generate plan'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 32, top: 8),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final entry = days[i];
                return _DaySection(
                  date: entry.key,
                  tasks: entry.value,
                  aiPlanned: app.state.lastPlanWasAi,
                );
              },
            ),
    );
  }
}

class _DaySection extends ConsumerWidget {
  final DateTime date;
  final List<PlanTask> tasks;
  final bool aiPlanned;

  const _DaySection({
    required this.date,
    required this.tasks,
    required this.aiPlanned,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isToday = date == today;
    final totalMinutes = tasks.fold<int>(
      0,
      (sum, t) => sum + t.plannedMinutes,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Text(
                isToday
                    ? 'Today'
                    : DateFormat('EEEE, MMM d').format(date),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isToday
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
              const Spacer(),
              Text(
                '${tasks.length} tasks · ${_fmt(totalMinutes)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        ...tasks.map(
          (task) => _PlanRow(task: task),
        ),
      ],
    );
  }

  String _fmt(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _PlanRow extends StatelessWidget {
  final PlanTask task;

  const _PlanRow({required this.task});

  @override
  Widget build(BuildContext context) {
    final color = Color(task.subjectColorValue);
    final done = task.status == TaskStatus.done;
    final skipped = task.status == TaskStatus.skipped;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.topicTitle,
              style: TextStyle(
                decoration: done ? TextDecoration.lineThrough : null,
                color: skipped ? Theme.of(context).disabledColor : null,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            task.subjectName,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${task.plannedMinutes}m',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
