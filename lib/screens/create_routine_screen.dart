import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_style.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/icon_badge.dart';

class SetEntry {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController repsMinController = TextEditingController();
  final TextEditingController repsMaxController = TextEditingController();
}

class ExerciseEntry {
  final Map<String, dynamic> exercise;
  final List<SetEntry> sets = [SetEntry()];

  ExerciseEntry(this.exercise);
}

class CreateRoutineScreen extends StatefulWidget {
  const CreateRoutineScreen({super.key});

  @override
  State<CreateRoutineScreen> createState() => _CreateRoutineScreenState();
}

class _CreateRoutineScreenState extends State<CreateRoutineScreen> {
  final TextEditingController nameController = TextEditingController();
  List<dynamic> availableExercises = [];
  final List<ExerciseEntry> entries = [];
  String message = '';

  @override
  void initState() {
    super.initState();
    loadAvailableExercises();
  }

  Future<void> loadAvailableExercises() async {
    try {
      final result = await ApiClient.getExercises();
      setState(() {
        availableExercises = result;
      });
    } catch (e) {
      setState(() {
        message = e.toString();
      });
    }
  }

  Future<void> openExercisePicker() async {
    final picked = await showExercisePicker(context, availableExercises);
    if (picked == null) return;
    setState(() {
      entries.add(ExerciseEntry(picked));
    });
  }

  Future<void> submit() async {
    try {
      final List<Map<String, dynamic>> exercises = [];

      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final List<Map<String, dynamic>> sets = [];
        for (int s = 0; s < entry.sets.length; s++) {
          final setEntry = entry.sets[s];
          sets.add({
            'setNumber': s + 1,
            'targetWeight': double.parse(setEntry.weightController.text),
            'targetRepsMin': int.parse(setEntry.repsMinController.text),
            'targetRepsMax': int.parse(setEntry.repsMaxController.text),
            'targetDurationSeconds': null,
            'setType': 'WORKING',
          });
        }

        exercises.add({
          'exerciseId': entry.exercise['id'],
          'exerciseOrder': i + 1,
          'exerciseNote': '',
          'supersetGroupId': null,
          'sets': sets,
        });
      }

      await ApiClient.createRoutine({
        'name': nameController.text,
        'notes': '',
        'folderOrder': 1,
        'exercises': exercises,
      });

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New routine')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Routine name'),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final entry in entries)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconBadge(
                          icon: iconForExerciseType(entry.exercise['exerciseType']),
                          color: colorForExerciseType(entry.exercise['exerciseType']),
                          size: 36,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.exercise['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            setState(() {
                              entries.remove(entry);
                            });
                          },
                        ),
                      ],
                    ),
                    for (int s = 0; s < entry.sets.length; s++)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          children: [
                            SizedBox(width: 48, child: Text('Set ${s + 1}', style: TextStyle(color: AppColors.textSecondary))),
                            Expanded(
                              child: TextField(
                                controller: entry.sets[s].weightController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: TextField(
                                controller: entry.sets[s].repsMinController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Min reps'),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: TextField(
                                controller: entry.sets[s].repsMaxController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Max reps'),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  entry.sets.removeAt(s);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          entry.sets.add(SetEntry());
                        });
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add set'),
                    ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: openExercisePicker,
            icon: const Icon(Icons.add),
            label: const Text('Add exercise'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: submit,
            child: const Text('Create routine'),
          ),
          if (message.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}
