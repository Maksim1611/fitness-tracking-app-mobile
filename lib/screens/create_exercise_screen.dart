import 'package:flutter/material.dart';

import '../services/api_client.dart';

const List<String> exerciseTypes = [
  'WEIGHT_REPS', 'REPS_ONLY', 'BODYWEIGHT', 'WEIGHTED_BODYWEIGHT',
  'ASSISTED_BODYWEIGHT', 'DURATION', 'WEIGHT_DURATION', 'DISTANCE',
];

const List<String> equipmentOptions = [
  'BARBELL', 'DUMBBELL', 'MACHINE', 'CABLE', 'BODYWEIGHT',
  'RESISTANCE_BAND', 'KETTLEBELL', 'PLATE', 'OTHER',
];

const List<String> muscleGroups = [
  'CHEST', 'BACK', 'QUADS', 'HAMSTRINGS', 'GLUTES', 'SHOULDERS',
  'BICEPS', 'TRICEPS', 'CORE', 'CALVES', 'FULL_BODY', 'NECK',
  'FOREARMS', 'LATS', 'UPPER_BACK', 'LOWER_BACK', 'TRAPS', 'CARDIO', 'OTHER',
];

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  final TextEditingController nameController = TextEditingController();
  String exerciseType = 'WEIGHT_REPS';
  String equipment = 'BARBELL';
  String muscleGroup = 'CHEST';
  String message = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New exercise')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: exerciseType,
                  decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                  items: exerciseTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (value) => setState(() => exerciseType = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: equipment,
                  decoration: const InputDecoration(labelText: 'Equipment', border: OutlineInputBorder()),
                  items: equipmentOptions.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (value) => setState(() => equipment = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: muscleGroup,
                  decoration: const InputDecoration(labelText: 'Primary muscle', border: OutlineInputBorder()),
                  items: muscleGroups.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                  onChanged: (value) => setState(() => muscleGroup = value!),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  onPressed: () async {
                    try {
                      await ApiClient.createExercise(
                        nameController.text, exerciseType, equipment, muscleGroup,
                      );
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                    } catch (e) {
                      setState(() => message = e.toString());
                    }
                  },
                  child: const Text('Create'),
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}