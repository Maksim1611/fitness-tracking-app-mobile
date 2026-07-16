import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'create_exercise_screen.dart';

class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key});

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  List<dynamic> exercises = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  Future<void> loadExercises() async {
    try {
      final result = await ApiClient.getExercises();
      setState(() {
        exercises = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My exercises')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : exercises.isEmpty
          ? const Center(child: Text('No exercises yet — create your first one!'))
          : ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ListTile(
            leading: const Icon(Icons.fitness_center),
            title: Text(exercise['name']),
            subtitle: Text('${exercise['primaryMuscleGroup']} • ${exercise['equipment']}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateExerciseScreen()),
          );
          if (created == true) {
            setState(() => loading = true);
            loadExercises();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}