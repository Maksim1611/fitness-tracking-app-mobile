import 'package:flutter/material.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final Map<String, dynamic> workout;

  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    final Map<String, List<dynamic>> byExercise = {};
    for (final set in workout['sets']) {
      byExercise.putIfAbsent(set['exerciseName'], () => []).add(set);
    }

    return Scaffold(
      appBar: AppBar(title: Text(workout['name'] ?? 'Workout')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final entry in byExercise.entries)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    for (int i = 0; i < entry.value.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Set ${i + 1}: '
                              '${entry.value[i]['weight'] ?? '—'} kg × ${entry.value[i]['reps'] ?? '—'}'
                              '${entry.value[i]['rpe'] != null ? ' @ RPE ${entry.value[i]['rpe']}' : ''}'
                              '${entry.value[i]['completed'] == true ? '  ✓' : '  (skipped)'}'
                              '${entry.value[i]['isPersonalRecord'] == true ? '  🏆' : ''}',
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}