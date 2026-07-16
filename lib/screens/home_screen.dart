import 'package:flutter/material.dart';

import '../services/api_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    );
  }
}