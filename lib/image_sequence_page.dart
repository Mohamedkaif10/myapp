import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ImageSequencePage extends StatefulWidget {
  final String folderName; // e.g., "John_45"
  const ImageSequencePage({super.key, required this.folderName});

  @override
  State<ImageSequencePage> createState() => _ImageSequencePageState();
}

class _ImageSequencePageState extends State<ImageSequencePage> {
  final List<String> instructions = [
    'Front teeth (closed bite)',
    'Right side front teeth (closed bite)',
    'Left side front teeth (closed bite)',
    'Upper jaw (maxillary occlusal view)',
    'Lower jaw (mandibular occlusal view)',
    'Right cheek (buccal view)',
    'Left cheek (buccal view)',
  ];

  final Map<String, String> referenceImages = {
    'Front teeth (closed bite)': 'assets/images/1.png',
    'Right side front teeth (closed bite)': 'assets/images/2.png',
    'Left side front teeth (closed bite)': 'assets/images/3.png',
    'Upper jaw (maxillary occlusal view)': 'assets/images/4.png',
    'Lower jaw (mandibular occlusal view)': 'assets/images/5.png',
    'Right cheek (buccal view)': 'assets/images/6.png',
    'Left cheek (buccal view)': 'assets/images/7.png',
  };

  int currentStep = 0;
  XFile? capturedImage;
  final ImagePicker picker = ImagePicker();

  Future<void> captureImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        capturedImage = image;
      });
    }
  }

  Future<void> saveImageLocally() async {
    final baseDir = Directory('/storage/emulated/0/Documents/myapp');
    final patientFolder = Directory('${baseDir.path}/${widget.folderName}');
    if (!await patientFolder.exists()) {
      await patientFolder.create(recursive: true);
    }

    final fileName = instructions[currentStep]
            .replaceAll(' ', '_')
            .replaceAll('(', '')
            .replaceAll(')', '')
            .replaceAll(':', '') +
        '.jpg';

    final path = '${patientFolder.path}/$fileName';
    await File(capturedImage!.path).copy(path);
  }

  Future<void> zipFolder() async {
    EasyLoading.show(status: 'Zipping...');

    final folderPath =
        '/storage/emulated/0/Documents/myapp/${widget.folderName}';
    final zipFilePath =
        '/storage/emulated/0/Documents/myapp/${widget.folderName}.zip'; // OUTSIDE the folder

    final zipEncoder = ZipFileEncoder();
    zipEncoder.create(zipFilePath);
    zipEncoder.addDirectory(Directory(folderPath));
    zipEncoder.close();

    EasyLoading.dismiss();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green[600],
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Thank you! All data captured and zipped.')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = instructions[currentStep];
    final referenceImagePath = referenceImages[instruction];

    return Scaffold(
      appBar: AppBar(
        title: Text('Step ${currentStep + 1} of ${instructions.length}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3FBF8B),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (referenceImagePath != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(referenceImagePath, height: 180),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          instruction,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: captureImage,
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3FBF8B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (capturedImage != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(capturedImage!.path),
                                height: 250),
                          )
                        else
                          const Text('No image captured yet'),
                      ],
                    ),
                  ),
                ),
                if (capturedImage != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      OutlinedButton.icon(
                        onPressed: captureImage,
                        icon: const Icon(
                          Icons.refresh,
                          color: Color(0xFF7F56D9),
                        ),
                        label: const Text(
                          'Retake',
                          style: TextStyle(color: Color(0xFF7F56D9)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7F56D9)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await saveImageLocally();
                          if (currentStep < instructions.length - 1) {
                            setState(() {
                              currentStep++;
                              capturedImage = null;
                            });
                          } else {
                            await zipFolder(); // Call zip logic
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save & Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3FBF8B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
