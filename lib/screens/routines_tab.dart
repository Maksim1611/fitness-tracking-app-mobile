import 'package:fitness_app_mobile/screens/routine_detail_screen.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'create_routine_screen.dart';

class RoutinesTab extends StatefulWidget {
  const RoutinesTab({super.key});

  @override
  State<RoutinesTab> createState() => _RoutinesTabState();
}

class _RoutinesTabState extends State<RoutinesTab> {
  List<dynamic> routines = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadRoutines();
  }

  Future<void> loadRoutines() async {
    try {
      final result = await ApiClient.getRoutines();
      setState(() {
        routines = result;
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
      appBar: AppBar(title: const Text('My routines')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : routines.isEmpty
          ? const Center(child: Text('No routines yet'))
          : ListView.builder(
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          final exerciseCount = (routine['exercises'] as List).length;
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.list_alt),
              title: Text(routine['name']),
              subtitle: Text('$exerciseCount exercises'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RoutineDetailScreen(routine: routine)),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateRoutineScreen()),
          );
          if (created == true) {
            setState(() => loading = true);
            loadRoutines();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}