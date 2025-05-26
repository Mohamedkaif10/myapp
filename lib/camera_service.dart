import 'dart:io';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  static Future<bool> _checkPermissions() async {
    final cameraStatus = await Permission.camera.request();
    final storageStatus = await Permission.storage.request();
    return cameraStatus.isGranted && storageStatus.isGranted;
  }

  static Future<CameraController?> initializeCamera() async {
    if (!await _checkPermissions()) return null;

    final cameras = await availableCameras();
    final controller = CameraController(
      cameras.first,
      ResolutionPreset.medium,
    );
    await controller.initialize();
    return controller;
  }

  static Future<File?> capturePhoto(CameraController controller) async {
    try {
      final image = await controller.takePicture();
      return File(image.path);
    } catch (e) {
      return null;
    }
  }

  static Future<String?> saveToOralVisFolder(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final oralVisDir = Directory(path.join(directory.path, 'oralvis'));
    
    if (!await oralVisDir.exists()) {
      await oralVisDir.create(recursive: true);
    }

    final fileName = 'oral_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final newPath = path.join(oralVisDir.path, fileName);
    
    try {
      await imageFile.copy(newPath);
      return newPath;
    } catch (e) {
      return null;
    }
  }
}