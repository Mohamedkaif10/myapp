import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'camera_service.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  File? _capturedImage;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = await CameraService.initializeCamera();
    if (_controller != null) {
      setState(() {});
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null) return;
    
    final imageFile = await CameraService.capturePhoto(_controller!);
    if (imageFile != null) {
      setState(() => _capturedImage = imageFile);
    }
  }

  Future<void> _savePhoto() async {
    if (_capturedImage == null) return;
    
    final savedPath = await CameraService.saveToOralVisFolder(_capturedImage!);
    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to: $savedPath')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OralVis Camera')),
      body: Column(
        children: [
          Expanded(
            child: _capturedImage != null
                ? Image.file(_capturedImage!)
                : _controller != null
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator()),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: _takePhoto,
                  child: const Text('Capture'),
                ),
                if (_capturedImage != null)
                  ElevatedButton(
                    onPressed: _savePhoto,
                    child: const Text('Save to OralVis'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}