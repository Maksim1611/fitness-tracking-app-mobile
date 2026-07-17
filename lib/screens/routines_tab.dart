import 'package:fitness_app_mobile/screens/routine_detail_screen.dart';
import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import 'active_workout_screen.dart';
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

  Future<void> startRoutine(Map<String, dynamic> routine) async {
    try {
      final workout = await ApiClient.startWorkout(routine['id']);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ActiveWorkoutScreen(workout: workout)),
      );
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  Future<void> confirmDelete(Map<String, dynamic> routine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete routine?'),
        content: Text('Delete "${routine['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiClient.deleteRoutine(routine['id']);
      setState(() {
        routines.remove(routine);
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Future<void> openDetail(Map<String, dynamic> routine) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RoutineDetailScreen(routine: routine)),
    );
    setState(() => loading = true);
    loadRoutines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Routines')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error, style: const TextStyle(color: AppColors.danger)))
          : routines.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, size: 56, color: AppColors.textSecondary.withAlpha(120)),
                  const SizedBox(height: AppSpacing.md),
                  Text('No routines yet — create your first one!', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
        itemCount: routines.length,
        itemBuilder: (context, index) {
          final routine = routines[index];
          final List exercises = routine['exercises'];

          return Card(
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              onTap: () => openDetail(routine),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            routine['name'],
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(Icons.more_vert, color: AppColors.textSecondary),
                          color: AppColors.surfaceHigh,
                          onSelected: (value) {
                            if (value == 'edit') openDetail(routine);
                            if (value == 'delete') confirmDelete(routine);
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.danger))),
                          ],
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Text(
                        exercises.isEmpty
                            ? 'No exercises yet'
                            : exercises.map((e) => e['exercise']['name']).join(' • '),
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          onPressed: () => startRoutine(routine),
                          icon: const Icon(Icons.play_arrow, size: 20),
                          label: const Text('Start routine'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
