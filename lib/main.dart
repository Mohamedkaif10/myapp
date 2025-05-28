import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:excel/excel.dart' show Excel, CellValue, TextCellValue;
import 'dart:io';
import 'image_sequence_page.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dentist Data Collection',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
       
      home: const PatientEntryPage(),
       builder: EasyLoading.init(),
    );
  }
}

class PatientEntryPage extends StatefulWidget {
  const PatientEntryPage({super.key});

  @override
  State<PatientEntryPage> createState() => _PatientEntryPageState();
}

class _PatientEntryPageState extends State<PatientEntryPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  String selectedGender = 'Male';

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

    if (!await _requestPermissions()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission denied')),
      );
      return;
    }

    try {
      // Generate folder name
      final folderName =
          "${name.replaceAll(' ', '_')}_${phone.substring(phone.length - 2)}";

      // Set path to: /storage/emulated/0/Documents/myapp/{folderName}
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
            builder: (context) => ImageSequencePage(folderName: folderName),
          ),
        );

// Clear fields after returning
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
            const SizedBox(height: 100),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/oralvis_logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Powered by OralVis',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
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
