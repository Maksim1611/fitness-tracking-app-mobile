import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/workout_stats.dart';
import '../widgets/stat_tile.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final stats = WorkoutStats.fromWorkout(workout);

    final Map<String, List<dynamic>> byExercise = {};
    for (final set in workout['sets']) {
      byExercise.putIfAbsent(set['exerciseName'], () => []).add(set);
    }

    return Scaffold(
      appBar: AppBar(title: Text(workout['name'] ?? 'Workout')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
        children: [
          Text(
            formatRelativeDate(workout['startedAt']),
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              if (stats.duration != null) ...[
                Expanded(child: StatTile(value: formatDuration(stats.duration!), label: 'Duration', icon: Icons.schedule)),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(child: StatTile(value: formatVolume(stats.totalVolume), label: 'Volume', icon: Icons.monitor_weight_outlined, color: AppColors.success)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: StatTile(value: '${stats.completedSets}', label: 'Sets', icon: Icons.format_list_numbered, color: AppColors.cardio)),
              if (stats.prCount > 0) ...[
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: StatTile(value: '${stats.prCount}', label: 'PRs', icon: Icons.emoji_events, color: AppColors.cardio)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final entry in byExercise.entries)
            Card(
              margin: const EdgeInsets.only(top: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        SizedBox(width: 36, child: Text('SET', style: _headerStyle)),
                        Expanded(child: Text('WEIGHT × REPS', style: _headerStyle)),
                        SizedBox(width: 48, child: Text('RPE', style: _headerStyle, textAlign: TextAlign.right)),
                        const SizedBox(width: 32),
                      ],
                    ),
                    const Divider(height: AppSpacing.md),
                    for (int i = 0; i < entry.value.length; i++)
                      _SetRow(index: i + 1, set: entry.value[i]),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  static TextStyle get _headerStyle => TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    letterSpacing: 0.6,
  );
}

class _SetRow extends StatelessWidget {
  final int index;
  final Map<String, dynamic> set;

  const _SetRow({required this.index, required this.set});

  @override
  Widget build(BuildContext context) {
    final completed = set['completed'] == true;
    final isPr = set['isPersonalRecord'] == true;
    final weight = set['weight'];
    final reps = set['reps'];
    final durationSeconds = set['durationSeconds'];

    String performance;
    if (durationSeconds != null) {
      performance = formatDuration(Duration(seconds: durationSeconds));
      if (weight != null) performance = '$weight kg × $performance';
    } else {
      performance = '${weight ?? '—'} kg × ${reps ?? '—'}';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text('$index', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              performance,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: completed ? AppColors.textPrimary : AppColors.textSecondary,
                decoration: completed ? null : TextDecoration.lineThrough,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              set['rpe'] != null ? '${set['rpe']}' : '—',
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          SizedBox(
            width: 32,
            child: isPr
                ? const Icon(Icons.emoji_events, size: 16, color: AppColors.cardio)
                : completed
                ? const Icon(Icons.check, size: 16, color: AppColors.success)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
