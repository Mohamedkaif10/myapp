import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class ImageSequencePage extends StatefulWidget {
  final String folderName;
  const ImageSequencePage({super.key, required this.folderName});

  @override
  State<ImageSequencePage> createState() => _ImageSequencePageState();
}

Future<void> zipFolderInBackground(String folderName) async {
  final folderPath = '/storage/emulated/0/Documents/myapp/$folderName';
  final zipFilePath = '/storage/emulated/0/Documents/myapp/${folderName}.zip';

  final zipEncoder = ZipFileEncoder();
  zipEncoder.create(zipFilePath);
  await zipEncoder.addDirectory(Directory(folderPath));
  zipEncoder.close();
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

  bool isMirrored = false;
  int currentStep = 0;
  XFile? capturedImage;
  final ImagePicker picker = ImagePicker();
  bool _isLoading = false;

  Future<void> captureImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        capturedImage = image;
      });
    }
  }

  Future<void> saveImageLocally() async {
    const clinicId = 132;
    const patientId = 14;
    final serialNumber = currentStep + 1;

    final baseDir = Directory('/storage/emulated/0/Documents/myapp');
    final patientFolder = Directory('${baseDir.path}/${widget.folderName}');
    if (!await patientFolder.exists()) {
      await patientFolder.create(recursive: true);
    }

    // final fileName = instructions[currentStep]
    //         .replaceAll(' ', '_')
    //         .replaceAll('(', '')
    //         .replaceAll(')', '')
    //         .replaceAll(':', '') +
    //     '.jpg';
    final fileName = '${clinicId}_${patientId}_$serialNumber.jpg';

    final path = '${patientFolder.path}/$fileName';
    await File(capturedImage!.path).copy(path);
  }

  Future<void> zipFolder() async {
    EasyLoading.show(status: 'Zipping images...');
    try {
      await compute(zipFolderInBackground, widget.folderName);
      if (context.mounted) {
        EasyLoading.dismiss();
        EasyLoading.showSuccess('Zipped successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green[600],
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(
                    child: Text('Thank you! All data captured and zipped.')),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      EasyLoading.dismiss();
      if (context.mounted) {
        EasyLoading.showError('Error zipping files');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error zipping files: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final instruction = instructions[currentStep];
    final referenceImagePath = referenceImages[instruction];

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text('Step ${currentStep + 1} of ${instructions.length}'),
            centerTitle: true,
            backgroundColor: const Color(0xFF3FBF8B),
            foregroundColor: Colors.white,
          ),
          body: Padding(
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
                            child: Image.asset(referenceImagePath, height: 220),
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
                            child: Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..scale(isMirrored ? -1.0 : 1.0, 1.0),
                              child: Image.file(File(capturedImage!.path),
                                  height: 250),
                            ),
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
                        icon:
                            const Icon(Icons.refresh, color: Color(0xFF7F56D9)),
                        label: const Text('Retake',
                            style: TextStyle(color: Color(0xFF7F56D9))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7F56D9)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            isMirrored = !isMirrored;
                          });
                        },
                        icon: const Icon(Icons.flip),
                        label: Text(
                          isMirrored ? 'Original' : 'Mirror',
                          style: const TextStyle(color: Color(0xFF7F56D9)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7F56D9)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await saveImageLocally();
                          if (currentStep < instructions.length - 1) {
                            setState(() {
                              currentStep++;
                              capturedImage = null;
                              isMirrored = false;
                            });
                          } else {
                            await zipFolder();
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save & Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3FBF8B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF3FBF8B)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Zipping...',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
