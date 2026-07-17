import 'package:flutter/material.dart';

import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/exercise_style.dart';
import '../utils/text_format.dart';
import '../widgets/icon_badge.dart';
import 'create_exercise_screen.dart';
import 'edit_exercise_screen.dart';

class ExercisesTab extends StatefulWidget {
  const ExercisesTab({super.key});

  @override
  State<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends State<ExercisesTab> {
  List<dynamic> exercises = [];
  bool loading = true;
  String error = '';
  String searchQuery = '';
  String? filterMuscleGroup;
  String? filterEquipment;

  Future<void> confirmDelete(Map<String, dynamic> exercise) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete exercise?'),
        content: Text('Delete "${exercise['name']}"? This cannot be undone.'),
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
      await ApiClient.deleteExercise(exercise['id']);
      setState(() {
        exercises.remove(exercise);
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    loadExercises();
  }

  Future<void> loadExercises() async {
    try {
      final result = await ApiClient.getExercises(
        muscleGroup: filterMuscleGroup,
        equipment: filterEquipment,
      );
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

  Future<void> showFilterDialog() async {
    String? selectedMuscleGroup = filterMuscleGroup;
    String? selectedEquipment = filterEquipment;

    final applied = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter exercises'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                initialValue: selectedMuscleGroup,
                decoration: const InputDecoration(labelText: 'Muscle group'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...muscleGroups.map((m) => DropdownMenuItem(value: m, child: Text(titleCaseEnum(m)))),
                ],
                onChanged: (value) => setDialogState(() => selectedMuscleGroup = value),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String?>(
                initialValue: selectedEquipment,
                decoration: const InputDecoration(labelText: 'Equipment'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Any')),
                  ...equipmentOptions.map((e) => DropdownMenuItem(value: e, child: Text(titleCaseEnum(e)))),
                ],
                onChanged: (value) => setDialogState(() => selectedEquipment = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                selectedMuscleGroup = null;
                selectedEquipment = null;
                Navigator.pop(context, true);
              },
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );

    if (applied != true) return;

    setState(() {
      filterMuscleGroup = selectedMuscleGroup;
      filterEquipment = selectedEquipment;
      loading = true;
    });
    loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    final filterActive = filterMuscleGroup != null || filterEquipment != null;
    final visibleExercises = searchQuery.isEmpty
        ? exercises
        : exercises
            .where((e) => (e['name'] as String).toLowerCase().contains(searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        actions: [
          IconButton(
            icon: Icon(filterActive ? Icons.filter_alt : Icons.filter_alt_outlined,
                color: filterActive ? AppColors.accent : null),
            onPressed: showFilterDialog,
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(
              child: Text(error, style: const TextStyle(color: AppColors.danger)),
            )
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
            child: TextField(
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: visibleExercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fitness_center, size: 56, color: AppColors.textSecondary.withAlpha(120)),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          searchQuery.isNotEmpty || filterActive
                              ? 'No exercises match'
                              : 'No exercises yet — create your first one!',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 96),
              itemCount: visibleExercises.length,
              itemBuilder: (context, index) {
                final exercise = visibleExercises[index];
                final exerciseType = exercise['exerciseType'] as String;
                final isCustom = exercise['custom'] == true;

                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    onTap: isCustom
                        ? () async {
                            final edited = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EditExerciseScreen(exercise: exercise)),
                            );
                            if (edited == true) {
                              setState(() => loading = true);
                              loadExercises();
                            }
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Row(
                        children: [
                          IconBadge(
                            icon: iconForExerciseType(exerciseType),
                            color: colorForExerciseType(exerciseType),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(exercise['name'], style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: 4,
                                  children: [
                                    _Tag(titleCaseEnum(exercise['primaryMuscleGroup'])),
                                    _Tag(titleCaseEnum(exercise['equipment'])),
                                    if (isCustom) const _Tag('Custom'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (isCustom)
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => confirmDelete(exercise),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

class _Tag extends StatelessWidget {
  final String label;

  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
      ),
    );
  }
}
