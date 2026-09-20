import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/subject.dart';
import '../providers.dart';
import '../widgets/limit_reached_sheet.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _palette = [
    0xFF6C7CFF,
    0xFFFF7A9A,
    0xFF35C48F,
    0xFFFFB13D,
    0xFF4FC3F7,
    0xFFB39DDB,
  ];

  static const _goals = [60, 90, 120, 180, 240, 300];

  final _nameController = TextEditingController();
  final _topicController = TextEditingController();
  DateTime? _examDate;
  int _priority = 2;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _addSubject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final app = ref.read(appControllerProvider);
    final color = _palette[app.subjects.length % _palette.length];
    final result = await app.addSubject(
      name,
      examDate: _examDate,
      priority: _priority,
      colorValue: color,
    );

    if (result == SubjectLimitResult.limitReached) {
      if (!mounted) return;
      showLimitReachedSheet(context);
      return;
    }

    setState(() {
      _nameController.clear();
      _topicController.clear();
      _examDate = null;
      _priority = 2;
    });
  }

  Future<void> _pickExamDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 14)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _examDate = picked);
  }

  Future<void> _generate() async {
    final app = ref.read(appControllerProvider);
    if (app.subjects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one subject first')),
      );
      return;
    }
    if (app.subjects.every((s) => s.topics.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add some topics to your subjects first'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final result = await app.generatePlan();
    if (!mounted) return;
    setState(() => _saving = false);

    if (result.limitReached) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('AI limit reached'),
          content: const Text(
            'You have used your 3 free AI plan generations. Continue with '
            'the offline planner or upgrade to Pro?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop('offline'),
              child: const Text('Offline plan'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop('upgrade'),
              child: const Text('Upgrade'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (choice == 'offline') {
        await app.generatePlan(forceOffline: true);
        if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
      } else if (choice == 'upgrade') {
        Navigator.of(context).pushNamed('/paywall');
      }
      return;
    }

    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Set up your plan',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _IntroText(subjects: app.subjects),
          const _Header('Daily study time'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in _goals)
                  ChoiceChip(
                    label: Text(_goalLabel(minutes)),
                    selected: app.state.dailyMinutesGoal == minutes,
                    onSelected: (_) => app.setDailyGoal(minutes),
                  ),
              ],
            ),
          ),
          const _Header('Subjects'),
          for (final subject in app.subjects)
            _SubjectEditor(subject: subject),
          _AddSubjectCard(
            nameController: _nameController,
            examDate: _examDate,
            priority: _priority,
            onPickDate: _pickExamDate,
            onPriorityChanged: (v) => setState(() => _priority = v ?? 2),
            onAdd: _addSubject,
          ),
          if (!app.state.isPro)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                app.subjects.isEmpty
                    ? 'Free plan: 1 subject, ${app.state.freeAiLimit} AI plans'
                    : 'Free plan allows 1 subject. Upgrade to Pro for '
                        'unlimited subjects.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: FilledButton.icon(
              onPressed: _saving ? null : _generate,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                _saving
                    ? 'Building your plan...'
                    : 'Generate my study plan',
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '$h hour${h > 1 ? 's' : ''}' : '$h h $m m';
  }
}

class _IntroText extends StatelessWidget {
  final List<Subject> subjects;

  const _IntroText({required this.subjects});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        subjects.isEmpty
            ? 'Add your subjects, topics and exam dates. StudyPilot will '
                'build a realistic daily plan.'
            : 'Ready to plan across ${subjects.length} '
                'subject${subjects.length > 1 ? 's' : ''}.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;

  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          letterSpacing: 1.2,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AddSubjectCard extends StatelessWidget {
  final TextEditingController nameController;
  final DateTime? examDate;
  final int priority;
  final VoidCallback onPickDate;
  final ValueChanged<int?> onPriorityChanged;
  final VoidCallback onAdd;

  const _AddSubjectCard({
    required this.nameController,
    required this.examDate,
    required this.priority,
    required this.onPickDate,
    required this.onPriorityChanged,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Subject name',
                hintText: 'e.g. DBMS, Thermodynamics, History',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: onPickDate,
                    borderRadius: BorderRadius.circular(10),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Exam date',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      child: Text(
                        examDate == null
                            ? 'Optional'
                            : DateFormat('MMM d, yyyy').format(examDate!),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: priority,
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('High')),
                    DropdownMenuItem(value: 2, child: Text('Med')),
                    DropdownMenuItem(value: 3, child: Text('Low')),
                  ],
                  onChanged: onPriorityChanged,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add subject'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectEditor extends ConsumerWidget {
  final Subject subject;

  const _SubjectEditor({required this.subject});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final color = Color(subject.colorValue);
    final topicController = TextEditingController();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: color.withValues(alpha: 0.10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subject.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  subject.examDate == null
                      ? 'no exam'
                      : DateFormat('MMM d').format(subject.examDate!),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => app.deleteSubject(subject),
                ),
              ],
            ),
            if (subject.topics.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final topic in subject.topics)
                      InputChip(
                        label: Text(topic.title),
                        onDeleted: () => app.deleteTopic(subject, topic),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: topicController,
                    decoration: const InputDecoration(
                      hintText: 'Add topic, e.g. Normalization',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (value) {
                      if (value.trim().isNotEmpty) {
                        app.addTopic(subject.id, value, 45);
                        topicController.clear();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (topicController.text.trim().isNotEmpty) {
                      app.addTopic(subject.id, topicController.text, 45);
                      topicController.clear();
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
