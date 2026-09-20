import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/subject.dart';
import '../models/topic.dart';
import '../providers.dart';

class SubjectDetailScreen extends ConsumerWidget {
  final String subjectId;

  const SubjectDetailScreen({super.key, required this.subjectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final subject = app.subjects
        .where((s) => s.id == subjectId)
        .firstOrNull;

    if (subject == null) {
      return const Scaffold(body: Center(child: Text('Subject not found')));
    }

    final color = Color(subject.colorValue);
    final controller = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          subject.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete subject',
            onPressed: () => _confirmDelete(context, ref, subject),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32, top: 8),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            elevation: 0,
            color: color.withValues(alpha: 0.10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _DetailChip(
                        icon: Icons.event,
                        label: subject.examDate == null
                            ? 'No exam date'
                            : DateFormat('MMM d, yyyy').format(
                                subject.examDate!,
                              ),
                      ),
                      _DetailChip(
                        icon: Icons.schedule,
                        label: '${subject.pendingMinutes} min left',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: subject.progress,
                      minHeight: 10,
                      backgroundColor: color.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${subject.doneCount}/${subject.topics.length} topics '
                    'completed',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'TOPICS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...subject.topics.map(
            (topic) => _TopicRow(
              topic: topic,
              color: color,
              onToggle: () =>
                  app.setTopicDone(subject, topic, !topic.done),
              onDelete: () => app.deleteTopic(subject, topic),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'New topic name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        app.addTopic(subject.id, value, 45);
                        controller.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (controller.text.trim().isNotEmpty) {
                      app.addTopic(subject.id, controller.text, 45);
                      controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Subject subject,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${subject.name}?'),
        content: const Text(
          'This removes the subject, its topics and planned tasks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appControllerProvider).deleteSubject(subject);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class _TopicRow extends StatelessWidget {
  final Topic topic;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TopicRow({
    required this.topic,
    required this.color,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onToggle,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: topic.done ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
        child: topic.done
            ? const Icon(Icons.check, size: 16, color: Colors.white)
            : null,
      ),
      title: Text(
        topic.title,
        style: TextStyle(
          decoration: topic.done ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text('${topic.estMinutes} min'),
      trailing: IconButton(
        icon: const Icon(Icons.close, size: 20),
        onPressed: onDelete,
      ),
    );
  }
}
