import 'package:fitness_app_mobile/screens/profile_tab.dart';
import 'package:fitness_app_mobile/screens/routines_tab.dart';
import 'package:fitness_app_mobile/screens/workouts_tab.dart';
import 'package:flutter/material.dart';

import 'exercises_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedIndex = 0;

  static const List<Widget> tabs = [
    WorkoutsTab(),
    RoutinesTab(),
    ExercisesTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: tabs[selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => setState(() => selectedIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.play_circle_outline), label: 'Workouts'),
          NavigationDestination(icon: Icon(Icons.list_alt), label: 'Routines'),
          NavigationDestination(icon: Icon(Icons.fitness_center), label: 'Exercises'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}