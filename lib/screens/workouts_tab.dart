import 'package:fitness_app_mobile/screens/workout_detail_screen.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'active_workout_screen.dart';

class WorkoutsTab extends StatefulWidget {
  const WorkoutsTab({super.key});

  @override
  State<WorkoutsTab> createState() => _WorkoutsTabState();
}

class _WorkoutsTabState extends State<WorkoutsTab> {
  List<dynamic> workouts = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadWorkouts();
  }

  Future<void> startWorkoutFlow() async {
    final routines = await ApiClient.getRoutines();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Start workout'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context);
              launchWorkout(null);
            },
            child: const Text('Empty workout'),
          ),
          for (final routine in routines)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                launchWorkout(routine['id']);
              },
              child: Text('From: ${routine['name']}'),
            ),
        ],
      ),
    );
  }

  Future<void> launchWorkout(String? routineId) async {
    try {
      final workout = await ApiClient.startWorkout(routineId);
      if (!context.mounted) return;
      final finished = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(workout: workout)),
      );
      if (finished == true) {
        setState(() => loading = true);
        loadWorkouts();
      }
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> loadWorkouts() async {
    try {
      final result = await ApiClient.getWorkouts();
      setState(() {
        workouts = result;
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
      appBar: AppBar(title: const Text('Workouts')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : workouts.isEmpty
          ? const Center(child: Text('No workouts yet — time for the first one!'))
          : ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          final bool finished = workout['finishedAt'] != null;
          final String date = workout['startedAt'].toString().substring(0, 10);
          final int setCount = (workout['sets'] as List).length;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: Icon(
                finished ? Icons.check_circle_outline : Icons.timelapse,
                color: finished ? Colors.green : Colors.orange,
              ),
              title: Text(workout['name'] ?? 'Workout'),
              subtitle: Text('$date • $setCount sets${finished ? '' : ' • in progress'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                if (finished) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => WorkoutDetailScreen(workout: workout)),
                  );
                } else {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(workout: workout)),
                  );
                  if (mounted) {
                    setState(() => loading = true);
                    loadWorkouts();
                  }
                }
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: startWorkoutFlow,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Start workout'),
      ),
    );
  }
}