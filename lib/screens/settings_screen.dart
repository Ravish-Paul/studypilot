import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/app_controller.dart';
import '../providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _goalOptions = [60, 90, 120, 180, 240, 300];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final app = ref.watch(appControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        actions: [
          if (!app.state.isPro)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).pushNamed('/paywall'),
                icon: const Icon(Icons.workspace_premium),
                label: const Text('Pro'),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32, top: 8),
        children: [
          _StatsCard(app: app),
          const _SectionHeader('Daily study goal'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final minutes in _goalOptions)
                  ChoiceChip(
                    label: Text(
                      minutes < 60
                          ? '$minutes min'
                          : '${minutes ~/ 60}h'
                          '${minutes % 60 == 0 ? '' : ' ${minutes % 60}m'}',
                    ),
                    selected: app.state.dailyMinutesGoal == minutes,
                    onSelected: (_) =>
                        ref.read(appControllerProvider).setDailyGoal(minutes),
                  ),
              ],
            ),
          ),
          const _SectionHeader('AI planning'),
          if (app.state.isPro)
            const _InfoTile(
              icon: Icons.workspace_premium,
              title: 'Pro active',
              subtitle: 'Unlimited AI plan generations and subjects',
            )
          else
            _InfoTile(
              icon: Icons.auto_awesome,
              title: '${app.aiPlansLeft} AI plans left',
              subtitle:
                  'Free plan includes ${app.state.freeAiLimit} AI generations '
                  'and unlimited offline planning',
            ),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('Purchases'),
            subtitle: const Text('Restore purchases or upgrade to Pro'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).pushNamed('/paywall'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Reset app data'),
            subtitle: const Text('Deletes all subjects, plans and progress'),
            onTap: () => _confirmReset(context, ref),
          ),
          const _SectionHeader('About'),
          const _InfoTile(
            icon: Icons.flight_takeoff,
            title: 'StudyPilot v1.0.0',
            subtitle:
                'AI adaptive study planner · Built for RevenueCat Shipaton '
                '2026 (Next Gen Award)',
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset app data?'),
        content: const Text(
          'This permanently deletes all subjects, plans, streaks and progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(appControllerProvider).resetAll();
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('App data reset')));
      }
    }
  }
}

class _StatsCard extends StatelessWidget {
  final AppController app;

  const _StatsCard({required this.app});

  @override
  Widget build(BuildContext context) {
    final streak = app.state.streakDays;
    final totalMinutes = app.state.totalStudyMinutes;
    final topicsDone = app.subjects.fold<int>(
      0,
      (sum, s) => sum + s.doneCount,
    );

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 0,
      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(
              icon: Icons.local_fire_department,
              color: Colors.orange,
              value: '$streak',
              label: streak == 1 ? 'day streak' : 'day streak',
            ),
            _Stat(
              icon: Icons.timer_outlined,
              color: Theme.of(context).colorScheme.primary,
              value: totalMinutes >= 60
                  ? '${totalMinutes ~/ 60}h'
                  : '$totalMinutes',
              label: 'focused',
            ),
            _Stat(
              icon: Icons.task_alt,
              color: Colors.green,
              value: '$topicsDone',
              label: 'topics done',
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  const _Stat({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
