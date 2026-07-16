import 'package:flutter/material.dart';

import '../services/api_client.dart';
import 'create_measurement_screen.dart';
import 'create_measurement_screen.dart';

class MeasurementsScreen extends StatefulWidget {
  const MeasurementsScreen({super.key});

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  List<dynamic> measurements = [];
  bool loading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    loadMeasurements();
  }

  Future<void> loadMeasurements() async {
    try {
      final result = await ApiClient.getMeasurements();
      setState(() {
        measurements = result;
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
      appBar: AppBar(title: const Text('Body measurements')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error.isNotEmpty
          ? Center(child: Text(error))
          : measurements.isEmpty
          ? const Center(child: Text('No measurements yet — log your first one!'))
          : ListView.builder(
        itemCount: measurements.length,
        itemBuilder: (context, index) {
          final m = measurements[index];
          final String date = m['recordedAt'].toString().substring(0, 10);
          final String extras = [
            if (m['bodyFatPercentage'] != null) '${m['bodyFatPercentage']}% bf',
            if (m['waist'] != null) 'waist ${m['waist']}',
            if (m['notes'] != null && m['notes'].toString().isNotEmpty) m['notes'],
          ].join(' • ');

          return ListTile(
            leading: const Icon(Icons.monitor_weight_outlined),
            title: Text('${m['weight']} kg'),
            subtitle: Text(extras.isEmpty ? date : '$date • $extras'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateMeasurementScreen()),
          );
          if (created == true) {
            setState(() => loading = true);
            loadMeasurements();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}