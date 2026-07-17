import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_style.dart';
import '../widgets/exercise_picker.dart';
import '../widgets/icon_badge.dart';

class RoutineDetailScreen extends StatefulWidget {
  final Map<String, dynamic> routine;

  const RoutineDetailScreen({super.key, required this.routine});

  @override
  State<RoutineDetailScreen> createState() => _RoutineDetailScreenState();
}

class _RoutineDetailScreenState extends State<RoutineDetailScreen> {
  late String routineId;
  late String routineName;
  late List<dynamic> exercises;
  List<dynamic> availableExercises = [];
  String error = '';

  @override
  void initState() {
    super.initState();
    routineId = widget.routine['id'];
    routineName = widget.routine['name'];
    exercises = List.from(widget.routine['exercises']);
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
        error = e.toString();
      });
    }
  }

  Future<void> renameRoutine() async {
    final controller = TextEditingController(text: routineName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename routine'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Routine name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (newName == null || newName.isEmpty || newName == routineName) return;

    try {
      await ApiClient.updateRoutineName(routineId, newName);
      setState(() {
        routineName = newName;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> confirmRemoveExercise(Map<String, dynamic> routineExercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove exercise?'),
        content: Text('Remove "${routineExercise['exercise']['name']}" from this routine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.removeExerciseFromRoutine(routineId, routineExercise['id']);
      setState(() {
        exercises.remove(routineExercise);
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> openExercisePicker() async {
    final picked = await showExercisePicker(context, availableExercises);

    if (picked == null) return;
    if (!mounted) return;
    await addExercise(picked);
  }

  Future<void> addExercise(Map<String, dynamic> exercise) async {
    final weightController = TextEditingController();
    final repsMinController = TextEditingController();
    final repsMaxController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add "${exercise['name']}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Target weight (kg)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: repsMinController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Min reps'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: repsMaxController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Max reps'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final added = await ApiClient.addExerciseToRoutine(routineId, {
        'exerciseId': exercise['id'],
        'exerciseOrder': exercises.length + 1,
        'exerciseNote': '',
        'supersetGroupId': null,
        'sets': [
          {
            'setNumber': 1,
            'targetWeight': double.tryParse(weightController.text) ?? 0,
            'targetRepsMin': int.tryParse(repsMinController.text) ?? 0,
            'targetRepsMax': int.tryParse(repsMaxController.text) ?? 0,
            'targetDurationSeconds': null,
            'setType': 'WORKING',
          },
        ],
      });
      setState(() {
        exercises.add(added);
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(routineName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: renameRoutine,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: Column(
        children: [
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(error, style: const TextStyle(color: AppColors.danger)),
            ),
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.list_alt, size: 56, color: AppColors.textSecondary.withAlpha(120)),
                        const SizedBox(height: AppSpacing.md),
                        Text('No exercises yet — tap + to add one', style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: exercises.length,
              itemBuilder: (context, index) {
                final routineExercise = exercises[index];
                final List sets = routineExercise['sets'];
                final exerciseType = routineExercise['exercise']['exerciseType'] as String;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconBadge(
                              icon: iconForExerciseType(exerciseType),
                              color: colorForExerciseType(exerciseType),
                              size: 36,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                routineExercise['exercise']['name'],
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => confirmRemoveExercise(routineExercise),
                            ),
                          ],
                        ),
                        for (final set in sets)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xs, left: 44),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceHigh,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text('Set ${set['setNumber']}',
                                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${set['targetWeight'] ?? '—'} kg × '
                                      '${set['targetRepsMin'] ?? '?'}–${set['targetRepsMax'] ?? '?'} reps',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openExercisePicker,
        child: const Icon(Icons.add),
      ),
    );
  }
}
