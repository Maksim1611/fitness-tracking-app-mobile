import 'package:flutter/material.dart';

class RoutineDetailScreen extends StatelessWidget {
  final Map<String, dynamic> routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  Widget build(BuildContext context) {
    final List exercises = routine['exercises'];

    return Scaffold(
      appBar: AppBar(title: Text(routine['name'])),
      body: ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          final List sets = exercise['sets'];

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise['exercise']['name'],
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  for (final set in sets)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Set ${set['setNumber']}: '
                            '${set['targetWeight'] ?? '—'} kg × '
                            '${set['targetRepsMin'] ?? '?'}–${set['targetRepsMax'] ?? '?'} reps',
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}