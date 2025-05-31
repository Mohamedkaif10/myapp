import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'patient_entry_page.dart';

class ImageSequencePage extends StatefulWidget {
  final String folderName;
  final int clinicId;
  final int patientId;

  const ImageSequencePage({
    super.key,
    required this.folderName,
    required this.clinicId,
    required this.patientId,
  });

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

  final Map<String, Uint8List> imageMemoryMap = {};
  bool isMirrored = false;
  int currentStep = 0;
  XFile? capturedImage;
  final ImagePicker picker = ImagePicker();
  bool _isLoading = false;
  final GlobalKey _imageKey = GlobalKey();

  Future<void> captureImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        capturedImage = image;
      });
    }
  }

  Future<void> saveImageToMemory() async {
    final clinicId = widget.clinicId;
    final patientId = widget.patientId;
    final serialNumber = currentStep + 1;
    final fileName = '${clinicId}_${patientId}_$serialNumber.png';

    try {
      RenderRepaintBoundary boundary =
          _imageKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      imageMemoryMap[fileName] = pngBytes;
      print('Stored $fileName in memory map');
    } catch (e) {
      print('Failed to render image: $e');
    }
  }

Future<void> zipImagesFromMemory() async {
  EasyLoading.show(status: 'Zipping images...');
  try {
    final zipPath = '/storage/emulated/0/Documents/myapp/${widget.folderName}.zip';
    final archive = Archive();

    // Add all image bytes from memory to archive
    for (final entry in imageMemoryMap.entries) {
      archive.addFile(ArchiveFile(entry.key, entry.value.length, entry.value));
    }

    // Optionally add Excel file from disk
    final excelPath = '/storage/emulated/0/Documents/myapp/${widget.folderName}.xlsx';
    final excelFile = File(excelPath);
    if (await excelFile.exists()) {
      final excelBytes = await excelFile.readAsBytes();
      archive.addFile(ArchiveFile('report.xlsx', excelBytes.length, excelBytes));
    }

    // Encode the archive and save it to disk
    final zipData = ZipEncoder().encode(archive);
    final zipFile = File(zipPath);
    await zipFile.writeAsBytes(zipData!);

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
              Expanded(child: Text('Thank you! All data captured and zipped.')),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: const Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pop();
      Navigator.of(context).pop();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PatientEntryPage(
            clinicName: 'Unknown',
            clinicId: widget.clinicId,
          ),
        ),
      );
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


  Matrix4 getTransformForStep(int step, bool isMirrored) {
    if (!isMirrored) return Matrix4.identity();
    if (step == 3 || step == 4) return Matrix4.identity()..scale(1.0, -1.0);
    if (step == 1 || step == 2) return Matrix4.identity()..scale(-1.0, 1.0);
    return Matrix4.identity();
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
                            child: Image.asset(
                              referenceImagePath,
                              height: MediaQuery.of(context).size.height * 0.35,
                              width: MediaQuery.of(context).size.width * 0.95,
                              fit: BoxFit.cover,
                            ),
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
                        if (capturedImage == null)
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
                                  vertical: 12, horizontal: 24),
                            ),
                          ),
                        const SizedBox(height: 20),
                        if (capturedImage != null)
                          RepaintBoundary(
                            key: _imageKey,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Transform(
                                alignment: Alignment.center,
                                transform: getTransformForStep(currentStep, isMirrored),
                                child: Image.file(File(capturedImage!.path),
                                    height: 250),
                              ),
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
                        icon: const Icon(Icons.refresh, color: Color(0xFF7F56D9)),
                        label: const Text('Retake',
                            style: TextStyle(color: Color(0xFF7F56D9))),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF7F56D9)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      if ([1, 2, 3, 4].contains(currentStep))
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await saveImageToMemory();
                          if (currentStep < instructions.length - 1) {
                            setState(() {
                              currentStep++;
                              capturedImage = null;
                              isMirrored = false;
                            });
                          } else {
                            await zipImagesFromMemory();
                          }
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save & Next'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3FBF8B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3FBF8B)),
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
