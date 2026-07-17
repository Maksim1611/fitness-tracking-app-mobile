import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_client.dart';
import '../theme/app_theme.dart';
import '../utils/text_format.dart';
import '../utils/workout_stats.dart';
import '../widgets/stat_tile.dart';
import '../widgets/user_avatar.dart';
import 'edit_profile_screen.dart';
import 'measurements_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? me;
  Map<String, dynamic>? socialProfile;
  List<dynamic> workouts = [];
  List<dynamic> badges = [];
  List<dynamic> muscleVolume = [];
  String error = '';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadAll();
  }

  Future<void> loadAll() async {
    try {
      final myself = await ApiClient.getMe();
      final results = await Future.wait([
        ApiClient.getWorkouts(),
        ApiClient.getBadges(),
        ApiClient.getMuscleGroupVolume(weeks: 4),
        ApiClient.getPublicProfile(myself['id']),
      ]);
      setState(() {
        me = myself;
        workouts = results[0] as List<dynamic>;
        badges = results[1] as List<dynamic>;
        muscleVolume = results[2] as List<dynamic>;
        socialProfile = results[3] as Map<String, dynamic>;
        loading = false;
        error = '';
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> logout() async {
    await ApiClient.logout();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  ({int workouts, double volume, int prs}) get lifetime {
    int count = 0;
    double volume = 0;
    int prs = 0;
    for (final workout in workouts) {
      if (workout['finishedAt'] == null) continue;
      count++;
      final stats = WorkoutStats.fromWorkout(workout);
      volume += stats.totalVolume;
      prs += stats.prCount;
    }
    return (workouts: count, volume: volume, prs: prs);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text(error, style: const TextStyle(color: AppColors.danger))),
      );
    }

    final totals = lifetime;
    final maxMuscleVolume = muscleVolume.fold<double>(
        0, (max, m) => (m['totalVolume'] as num) > max ? (m['totalVolume'] as num).toDouble() : max);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xl),
          children: [
            if (error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(error, style: const TextStyle(color: AppColors.danger)),
              ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                UserAvatar(imageUrl: me!['imageUrl'], name: me!['name'] ?? '?', radius: 32),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(me!['name'], style: Theme.of(context).textTheme.titleLarge),
                      Text('@${me!['username']}', style: TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final saved = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditProfileScreen(me: me!)),
                    );
                    if (saved == true) {
                      setState(() => loading = true);
                      loadAll();
                    }
                  },
                ),
              ],
            ),
            if (socialProfile != null) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Row(
                  children: [
                    _CountColumn(count: socialProfile!['workoutCount'], label: 'Workouts'),
                    _CountColumn(count: socialProfile!['followerCount'], label: 'Followers'),
                    _CountColumn(count: socialProfile!['followingCount'], label: 'Following'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),

            Row(
              children: [
                Expanded(child: StatTile(value: '${totals.workouts}', label: 'Workouts', icon: Icons.play_circle_outline)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: StatTile(value: formatVolume(totals.volume), label: 'Total volume', icon: Icons.monitor_weight_outlined, color: AppColors.success)),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: StatTile(value: '${totals.prs}', label: 'PRs', icon: Icons.emoji_events, color: AppColors.cardio)),
              ],
            ),

            if (badges.isNotEmpty) ...[
              SectionHeader('Badges', trailing: Text('${badges.length}', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [for (final badge in badges) _Badge(badge: badge)],
              ),
            ],

            if (muscleVolume.isNotEmpty) ...[
              const SectionHeader('Muscle volume (4 weeks)'),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: Column(
                  children: [
                    for (final muscle in muscleVolume)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 92,
                              child: Text(
                                titleCaseEnum(muscle['muscleGroup']),
                                style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: maxMuscleVolume == 0 ? 0 : (muscle['totalVolume'] as num) / maxMuscleVolume,
                                  minHeight: 8,
                                  backgroundColor: AppColors.surfaceHigh,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            SizedBox(
                              width: 64,
                              child: Text(
                                formatVolume((muscle['totalVolume'] as num).toDouble()),
                                textAlign: TextAlign.right,
                                style: TextStyle(fontSize: 12, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],

            const SectionHeader('Settings'),
            Card(
              child: Column(
                children: [
                  ValueListenableBuilder<bool>(
                    valueListenable: darkModeNotifier,
                    builder: (context, dark, _) => SwitchListTile(
                      title: const Text('Dark mode'),
                      secondary: Icon(dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined),
                      value: dark,
                      onChanged: (value) => saveThemeMode(value),
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.straighten),
                    title: const Text('Body measurements'),
                    trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MeasurementsScreen()),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.danger),
                    title: const Text('Log out', style: TextStyle(color: AppColors.danger)),
                    onTap: logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountColumn extends StatelessWidget {
  final dynamic count;
  final String label;

  const _CountColumn({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Map<String, dynamic> badge;

  const _Badge({required this.badge});

  static const tierColors = {
    'BRONZE': Color(0xFFCD7F32),
    'SILVER': Color(0xFFB8C0CC),
    'GOLD': Color(0xFFFFC94D),
    'DIAMOND': Color(0xFF6EE7F5),
    'MYTHICAL': Color(0xFFB86EF5),
  };

  @override
  Widget build(BuildContext context) {
    final color = tierColors[badge['tier']] ?? AppColors.accent;
    final muscle = badge['muscleGroup'];
    final label = [
      titleCaseEnum(badge['tier']),
      if (muscle != null) titleCaseEnum(muscle) else titleCaseEnum(badge['category']),
    ].join(' • ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(31),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 14, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}
