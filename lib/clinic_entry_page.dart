import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'patient_entry_page.dart';

class ClinicEntryPage extends StatefulWidget {
  const ClinicEntryPage({super.key});

  @override
  State<ClinicEntryPage> createState() => _ClinicEntryPageState();
}

class _ClinicEntryPageState extends State<ClinicEntryPage> {
  final TextEditingController _clinicNameController = TextEditingController();

  Future<void> _proceed() async {
    final name = _clinicNameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter clinic name')),
      );
      return;
    }

    final clinicId = 10000 + DateTime.now().millisecondsSinceEpoch % 90000;

    final db = await openDatabase(
      p.join(await getDatabasesPath(), 'oralvis.db'),
      onCreate: (db, version) {
        return db.execute('CREATE TABLE clinic(id INTEGER PRIMARY KEY, name TEXT)');
      },
      version: 1,
    );

    final existing = await db.query('clinic');
    if (existing.isEmpty) {
      await db.insert('clinic', {'id': clinicId, 'name': name});
    }

    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientEntryPage(clinicName: name, clinicId: clinicId),
        ),
      );
    }
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
