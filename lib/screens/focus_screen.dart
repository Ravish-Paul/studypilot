import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/plan_task.dart';
import '../providers.dart';

class FocusScreen extends ConsumerStatefulWidget {
  final PlanTask task;

  const FocusScreen({super.key, required this.task});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  static const _sessionSeconds = 25 * 60;

  late int _remaining;
  Timer? _timer;
  bool _running = false;
  late ConfettiController _confetti;
  bool _celebrated = false;

  @override
  void initState() {
    super.initState();
    _remaining = _sessionSeconds;
    _confetti = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _confetti.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remaining > 0) {
          _remaining--;
        } else {
          _timer?.cancel();
          _running = false;
          _celebrate();
        }
      });
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _remaining = _sessionSeconds;
      _celebrated = false;
    });
  }

  void _celebrate() {
    if (_celebrated) return;
    _celebrated = true;
    _confetti.play();
    ref.read(appControllerProvider).logStudyMinutes(widget.task.plannedMinutes);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Session done! ${widget.task.plannedMinutes} minutes logged.',
        ),
      ),
    );
  }

  Future<void> _completeTask() async {
    await ref
        .read(appControllerProvider)
        .setTaskStatus(widget.task, TaskStatus.done);
    if (mounted) Navigator.of(context).pop();
  }

  String get _label {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(widget.task.subjectColorValue);
    final progress = 1 - (_remaining / _sessionSeconds);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Focus session'),
        actions: [
          IconButton(icon: const Icon(Icons.restart_alt), onPressed: _reset),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.task.topicTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  '${widget.task.subjectName} · ${widget.task.plannedMinutes} min',
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        strokeCap: StrokeCap.round,
                        backgroundColor: color.withValues(alpha: 0.15),
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                      Text(
                        _label,
                        style: Theme.of(context).textTheme.displayMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _toggle,
                  icon: Icon(_running ? Icons.pause : Icons.play_arrow),
                  label: Text(_running ? 'Pause' : 'Start focus'),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: _completeTask,
                  icon: const Icon(Icons.check),
                  label: const Text('Mark task as done'),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: [
                color,
                Theme.of(context).colorScheme.primary,
                Colors.white,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
