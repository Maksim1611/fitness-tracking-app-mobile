import 'package:flutter/material.dart';

import '../services/api_client.dart';

class CreateMeasurementScreen extends StatefulWidget {
  const CreateMeasurementScreen({super.key});

  @override
  State<CreateMeasurementScreen> createState() => _CreateMeasurementScreenState();
}

class _CreateMeasurementScreenState extends State<CreateMeasurementScreen> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController bodyFatController = TextEditingController();
  final TextEditingController waistController = TextEditingController();
  final TextEditingController chestController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String message = '';

  Future<void> submit() async {
    try {
      final Map<String, dynamic> measurement = {
        'weight': double.parse(weightController.text),
        if (bodyFatController.text.isNotEmpty) 'bodyFatPercentage': double.parse(bodyFatController.text),
        if (waistController.text.isNotEmpty) 'waist': double.parse(waistController.text),
        if (chestController.text.isNotEmpty) 'chest': double.parse(chestController.text),
        if (notesController.text.isNotEmpty) 'notes': notesController.text,
      };

      await ApiClient.createMeasurement(measurement);

      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log measurement')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              TextField(
                controller: weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg) *'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bodyFatController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Body fat %'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: waistController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Waist (cm)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: chestController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Chest (cm)'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'Notes (e.g. fasted morning)'),
              ),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: submit,
                child: const Text('Save'),
              ),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}