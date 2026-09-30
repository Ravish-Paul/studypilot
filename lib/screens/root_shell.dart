import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../controllers/app_controller.dart';
import '../models/plan_task.dart';
import '../providers.dart';
import '../services/plan_service.dart';
import '../widgets/exam_countdown.dart';
import '../widgets/limit_reached_sheet.dart';
import '../widgets/subject_progress_card.dart';
import '../widgets/task_tile.dart';
import 'focus_screen.dart';
import 'plan_screen.dart';
import 'settings_screen.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [TodayPage(), PlanPage(), SettingsPage()];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.today_outlined),
            selectedIcon: Icon(Icons.today),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Plan',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class TodayPage extends ConsumerWidget {
  const TodayPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    final tasks = app.todayTasks;
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Today',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              DateFormat('EEEE, MMM d').format(today),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          if (app.state.streakDays > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                avatar: const Icon(
                  Icons.local_fire_department,
                  color: Colors.orange,
                  size: 20,
                ),
                label: Text('${app.state.streakDays}'),
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
              ),
            ),
          IconButton(
            tooltip: 'Adapt plan',
            icon: const Icon(Icons.auto_fix_high),
            onPressed: app.generatingPlan || !app.hasAnyPlan
                ? null
                : () => regeneratePlan(context, ref),
          ),
        ],
      ),
      body: !app.state.onboarded
          ? EmptyState(
              onGetStarted: () =>
                  Navigator.of(context).pushNamed('/onboarding'),
            )
          : ListView(
              children: [
                if (app.subjectsWithExams.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: SizedBox(
                      height: 40,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: app.subjectsWithExams.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 8),
                        itemBuilder: (context, i) => ExamCountdown(
                          subject: app.subjectsWithExams[i],
                        ),
                      ),
                    ),
                  ),
                TodaySummary(app: app),
                ...tasks.map(
                  (task) => TaskTile(
                    task: task,
                    onStatusChanged: (status) => ref
                        .read(appControllerProvider)
                        .setTaskStatus(task, status),
                    onFocus: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => FocusScreen(task: task),
                      ),
                    ),
                  ),
                ),
                if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      app.subjects.isEmpty
                          ? 'Add your subjects and exam dates to build a plan.'
                          : 'Nothing scheduled today. Use the adapt button to '
                                'rebuild your plan.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                if (app.subjects.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: FilledButton.icon(
                      onPressed: () =>
                          Navigator.of(context).pushNamed('/onboarding'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add subjects'),
                    ),
                  ),
                const SubjectsSection(),
                const SizedBox(height: 80),
              ],
            ),
      floatingActionButton: app.state.onboarded &&
              !app.hasAnyPlan &&
              app.subjects.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: () => regeneratePlan(context, ref),
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Generate plan'),
            )
          : null,
    );
  }
}

Future<void> regeneratePlan(BuildContext context, WidgetRef ref) async {
  final app = ref.read(appControllerProvider);
  if (app.subjects.isEmpty) {
    await Navigator.of(context).pushNamed('/onboarding');
    return;
  }
  final result = await app.generatePlan();
  if (!context.mounted) return;
  if (result.limitReached) {
    showLimitReachedSheet(context);
  } else {
    final source = result.source == PlanSource.ai ? 'AI' : 'offline';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plan adapted ($source planner)')),
    );
  }
}

class TodaySummary extends StatelessWidget {
  final AppController app;

  const TodaySummary({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final tasks = app.todayTasks;
    final remainingMinutes = tasks
        .where((t) => t.status == TaskStatus.todo)
        .fold<int>(0, (sum, t) => sum + t.plannedMinutes);
    final doneCount =
        tasks.where((t) => t.status != TaskStatus.todo).length;
    final allDone = tasks.isNotEmpty && doneCount == tasks.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
      child: Text(
        tasks.isEmpty
            ? 'Nothing scheduled today'
            : allDone
                ? 'All done for today. Great work!'
                : '$doneCount/${tasks.length} done · ${fmtMinutes(remainingMinutes)} left',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  String fmtMinutes(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class SubjectsSection extends ConsumerWidget {
  const SubjectsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);
    if (app.subjects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
          child: Text(
            'Subjects',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        ...app.subjects.map(
          (subject) => SubjectProgressCard(
            subject: subject,
            onTap: () => Navigator.of(
              context,
            ).pushNamed('/subject', arguments: subject.id),
          ),
        ),
      ],
    );
  }
}

class EmptyState extends StatelessWidget {
  final VoidCallback onGetStarted;

  const EmptyState({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_takeoff,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Welcome to StudyPilot',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your subjects and exam dates, and let AI build a daily '
              'study plan that adapts when life happens.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.rocket_launch),
              label: const Text('Get started'),
              onPressed: onGetStarted,
            ),
          ],
        ),
      ),
    );
  }
}
