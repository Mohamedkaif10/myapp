import 'package:flutter/material.dart';
import 'patient_entry_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OralVis App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const ClinicEntryPage(),
    );
  }
}

class ClinicEntryPage extends StatefulWidget {
  const ClinicEntryPage({super.key});

  @override
  State<ClinicEntryPage> createState() => _ClinicEntryPageState();
}

class _ClinicEntryPageState extends State<ClinicEntryPage> {
  final TextEditingController _clinicNameController = TextEditingController();
  late final int _clinicId;

  @override
  void initState() {
    super.initState();
    _clinicId = 10000 +
        DateTime.now().millisecondsSinceEpoch % 90000; // ✅ 5-digit clinic ID
  }

  void _proceed() {
    final name = _clinicNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinic name')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientEntryPage(
          clinicName: name,
          clinicId: _clinicId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter Clinic Info')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _clinicNameController,
              decoration: const InputDecoration(labelText: 'Clinic Name'),
            ),
            const SizedBox(height: 16),
            TextField(
              enabled: false,
              decoration: InputDecoration(
                labelText: 'Clinic ID',
                border: const OutlineInputBorder(),
                hintText: _clinicId.toString(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _proceed,
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}
