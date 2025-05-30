import 'package:flutter/material.dart';
import 'patient_entry_page.dart';

class ClinicEntryPage extends StatefulWidget {
  const ClinicEntryPage({super.key});

  @override
  State<ClinicEntryPage> createState() => _ClinicEntryPageState();
}

class _ClinicEntryPageState extends State<ClinicEntryPage> {
  final TextEditingController _clinicNameController = TextEditingController();

  void _proceed() {
    final name = _clinicNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinic name')),
      );
      return;
    }

    final clinicId = 10000 + DateTime.now().millisecondsSinceEpoch % 90000;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PatientEntryPage(clinicName: name, clinicId: clinicId),
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _proceed,
              child: const Text('Proceed'),
            )
          ],
        ),
      ),
    );
  }
}
