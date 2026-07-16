import 'package:flutter/material.dart';

import '../services/api_client.dart';

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

  void openExercisePicker() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Pick an exercise'),
        children: [
          for (final exercise in availableExercises)
            SimpleDialogOption(
              onPressed: () {
                setState(() {
                  entries.add(ExerciseEntry(exercise));
                });
                Navigator.pop(context);
              },
              child: Text(exercise['name']),
            ),
        ],
      ),
    );
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
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Routine name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (final entry in entries)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                      Row(
                        children: [
                          SizedBox(width: 48, child: Text('Set ${s + 1}')),
                          Expanded(
                            child: TextField(
                              controller: entry.sets[s].weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Weight (kg)'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: entry.sets[s].repsMinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Min reps'),
                            ),
                          ),
                          const SizedBox(width: 8),
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
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: submit,
            child: const Text('Create routine'),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}