import 'package:flutter/material.dart';

import '../services/api_client.dart';

class SetRow {
  final Map<String, dynamic> set;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController rpeController;
  bool completed;

  SetRow(this.set)
      : weightController = TextEditingController(text: set['weight']?.toString() ?? ''),
        repsController = TextEditingController(text: set['reps']?.toString() ?? ''),
        rpeController = TextEditingController(text: set['rpe']?.toString() ?? ''),
        completed = set['completed'] == true;
}

class ExerciseGroup {
  final String exerciseId;
  final String exerciseName;
  final List<SetRow> sets = [];

  ExerciseGroup(this.exerciseId, this.exerciseName);
}

class ActiveWorkoutScreen extends StatefulWidget {
  final Map<String, dynamic> workout;

  const ActiveWorkoutScreen({super.key, required this.workout});

  @override
  State<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends State<ActiveWorkoutScreen> {
  final List<ExerciseGroup> groups = [];
  List<dynamic> availableExercises = [];
  String message = '';

  @override
  void initState() {
    super.initState();
    final Map<String, ExerciseGroup> byExercise = {};
    for (final set in widget.workout['sets']) {
      final group = byExercise.putIfAbsent(
        set['exerciseId'],
            () => ExerciseGroup(set['exerciseId'], set['exerciseName']),
      );
      group.sets.add(SetRow(set));
    }
    groups.addAll(byExercise.values);
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

  Future<void> addSetToGroup(ExerciseGroup group) async {
    try {
      final newSet = await ApiClient.addSet(widget.workout['id'], group.exerciseId);
      setState(() {
        group.sets.add(SetRow(newSet));
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
        title: const Text('Add exercise'),
        children: [
          for (final exercise in availableExercises)
            SimpleDialogOption(
              onPressed: () async {
                Navigator.pop(context);
                try {
                  final newSet = await ApiClient.addSet(widget.workout['id'], exercise['id']);
                  setState(() {
                    ExerciseGroup? existing;
                    for (final g in groups) {
                      if (g.exerciseId == exercise['id']) {
                        existing = g;
                      }
                    }
                    if (existing != null) {
                      existing.sets.add(SetRow(newSet));
                    } else {
                      final group = ExerciseGroup(exercise['id'], exercise['name']);
                      group.sets.add(SetRow(newSet));
                      groups.add(group);
                    }
                  });
                } catch (e) {
                  setState(() {
                    message = e.toString();
                  });
                }
              },
              child: Text(exercise['name']),
            ),
        ],
      ),
    );
  }

  Future<void> toggleSet(SetRow row, bool value) async {
    try {
      final changes = <String, dynamic>{'completed': value};
      if (row.weightController.text.isNotEmpty) {
        changes['weight'] = double.parse(row.weightController.text);
      }
      if (row.repsController.text.isNotEmpty) {
        changes['reps'] = int.parse(row.repsController.text);
      }
      if (row.rpeController.text.isNotEmpty) {
        changes['rpe'] = double.parse(row.rpeController.text);
      }

      final updated = await ApiClient.updateSet(widget.workout['id'], row.set['id'], changes);

      setState(() {
        row.completed = updated['completed'] == true;
        if (updated['isPersonalRecord'] == true && value) {
          message = '🏆 PR on ${updated['exerciseName']}!';
        }
      });
    } catch (e) {
      setState(() {
        message = e.toString();
      });
    }
  }

  Future<void> finish() async {
    try {
      await ApiClient.finishWorkout(widget.workout['id']);
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
      appBar: AppBar(
        title: Text(widget.workout['name'] ?? 'Workout'),
        actions: [
          TextButton(onPressed: finish, child: const Text('FINISH')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          for (final group in groups)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.exerciseName, style: Theme.of(context).textTheme.titleMedium),
                    for (int i = 0; i < group.sets.length; i++)
                      Row(
                        children: [
                          SizedBox(width: 44, child: Text('Set ${i + 1}')),
                          Expanded(
                            child: TextField(
                              controller: group.sets[i].weightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'kg'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: group.sets[i].repsController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'reps'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: group.sets[i].rpeController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'RPE'),
                            ),
                          ),
                          Checkbox(
                            value: group.sets[i].completed,
                            onChanged: (value) => toggleSet(group.sets[i], value ?? false),
                          ),
                        ],
                      ),
                    TextButton.icon(
                      onPressed: () => addSetToGroup(group),
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
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}