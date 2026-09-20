import 'package:flutter/material.dart';

import '../models/subject.dart';

class ExamCountdown extends StatelessWidget {
  final Subject subject;

  const ExamCountdown({super.key, required this.subject});

  @override
  Widget build(BuildContext context) {
    final daysLeft = subject.daysLeft;
    if (daysLeft == null) return const SizedBox.shrink();
    final color = Color(subject.colorValue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: themeCardColor(context, color),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            daysLeft <= 7 ? Icons.local_fire_department : Icons.event,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            '${subject.name} · ${daysLeft <= 0 ? 'today' : '$daysLeft d'}',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color themeCardColor(BuildContext context, Color color) {
    final brightness = Theme.of(context).brightness;
    return brightness == Brightness.dark
        ? color.withValues(alpha: 0.12)
        : color.withValues(alpha: 0.08);
  }
}
