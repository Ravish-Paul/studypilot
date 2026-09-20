import 'package:flutter/material.dart';

import '../models/plan_task.dart';

class TaskTile extends StatelessWidget {
  final PlanTask task;
  final ValueChanged<TaskStatus> onStatusChanged;
  final VoidCallback? onFocus;

  const TaskTile({
    super.key,
    required this.task,
    required this.onStatusChanged,
    this.onFocus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = Color(task.subjectColorValue);
    final done = task.status == TaskStatus.done;
    final skipped = task.status == TaskStatus.skipped;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: skipped ? 0.45 : 1,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: ListTile(
          onTap: () => onStatusChanged(
            done ? TaskStatus.todo : TaskStatus.done,
          ),
          leading: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? color : Colors.transparent,
              border: Border.all(color: color, width: 2.2),
            ),
            child: done
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : null,
          ),
          title: Text(
            task.topicTitle,
            style: TextStyle(
              decoration: done ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    task.subjectName,
                    style: TextStyle(
                      color: color.withValues(alpha: 1),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${task.plannedMinutes} min',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          trailing: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'focus') {
                onFocus?.call();
              } else if (value == 'skip') {
                onStatusChanged(TaskStatus.skipped);
              } else if (value == 'reset') {
                onStatusChanged(TaskStatus.todo);
              }
            },
            itemBuilder: (context) => [
              if (onFocus != null)
                const PopupMenuItem(value: 'focus', child: Text('Focus timer')),
              if (!skipped && !done)
                const PopupMenuItem(
                  value: 'skip',
                  child: Text('Skip for now'),
                ),
              if (skipped || done)
                const PopupMenuItem(value: 'reset', child: Text('Reset')),
            ],
          ),
        ),
      ),
    );
  }
}
