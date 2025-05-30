import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' show Excel, TextCellValue;
import 'dart:io';
import 'image_sequence_page.dart';

class PatientEntryPage extends StatefulWidget {
  final String clinicName;
  final int clinicId;

  const PatientEntryPage(
      {super.key, required this.clinicName, required this.clinicId});

  @override
  State<PatientEntryPage> createState() => _PatientEntryPageState();
}

class _PatientEntryPageState extends State<PatientEntryPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedGender = 'Male';

  int _patientCounter = 1; // ✅ Properly placed here

  Future<void> saveToExcel() async {
    final name = nameController.text.trim();
    final age = ageController.text.trim();
    final phone = phoneController.text.trim();
    final gender = selectedGender;

    if (name.isEmpty || age.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (phone.length != 10 || !RegExp(r'^[0-9]+$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number must be exactly 10 digits')),
      );
      return;
    }

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    try {
      final folderName =
          "${name.replaceAll(' ', '_')}_${phone.substring(phone.length - 2)}";
      final baseDir = Directory('/storage/emulated/0/Documents/myapp');
      final patientFolder = Directory('${baseDir.path}/$folderName');
      if (!await patientFolder.exists()) {
        await patientFolder.create(recursive: true);
      }

      final filePath = "${patientFolder.path}/patients_data.xlsx";
      final file = File(filePath);
      Excel excel;

      if (file.existsSync()) {
        final bytes = file.readAsBytesSync();
        excel = Excel.decodeBytes(bytes);
      } else {
        excel = Excel.createExcel();
        excel['Patients'].appendRow([
          TextCellValue('Name'),
          TextCellValue('Age'),
          TextCellValue('Gender'),
          TextCellValue('Phone Number')
        ]);
      }

      final sheet = excel['Patients'];
      sheet.appendRow([
        TextCellValue(name),
        TextCellValue(age),
        TextCellValue(gender),
        TextCellValue(phone)
      ]);

      final fileBytes = excel.encode();
      await file.writeAsBytes(fileBytes!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Excel saved to: $filePath')),
      );

      if (context.mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImageSequencePage(
              folderName: folderName,
              clinicId: widget.clinicId,
              patientId: _patientCounter,
            ),
          ),
        );

        _patientCounter++; // ✅ Increment after use

        nameController.clear();
        ageController.clear();
        phoneController.clear();
        setState(() {
          selectedGender = 'Male';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving Excel: $e')),
      );
    }
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isAndroid) {
      if (await Permission.manageExternalStorage.isGranted) return true;
      final status = await Permission.manageExternalStorage.request();
      return status.isGranted;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Patient Data Collection')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clinic ID: ${widget.clinicId}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.teal,
              ),
            ),
            Text(
              'Patient ID: ${_patientCounter.toString().padLeft(3, '0')}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.deepOrange,
              ),
            ),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Patient Name'),
            ),
            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age'),
            ),
            DropdownButtonFormField<String>(
              value: selectedGender,
              items: ['Male', 'Female', 'Other']
                  .map((gender) =>
                      DropdownMenuItem(value: gender, child: Text(gender)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedGender = value!;
                });
              },
              decoration: const InputDecoration(labelText: 'Gender'),
            ),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: saveToExcel,
              child: const Text('Save and Next'),
            ),
          ],
        ),
      ),
    );
  }
}
