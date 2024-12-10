import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:inspection/screens/preview_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraCaptureScreen extends StatefulWidget {
  final CameraDescription camera;
  final String title;

  CameraCaptureScreen({required this.camera, required this.title});

  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<XFile> _capturedPhotos = [];
  bool _isPermissionGranted = false;
  bool _photoCaptured = false;
  XFile? _latestPhoto;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isDenied || status.isPermanentlyDenied) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _initializeCamera();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Камера недоступна, предоставьте разрешение.')),
      );
      Navigator.pop(context);
    }
  }

  void _initializeCamera() {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller!.initialize();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      await _initializeControllerFuture;

      final image = await _controller!.takePicture();

      setState(() {
        _latestPhoto = image;
        _capturedPhotos.add(image);
        _photoCaptured = true;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Camera Capture'),
      ),
      body: _isPermissionGranted
          ? Column(
        children: [
          FutureBuilder<void>(
            future: _initializeControllerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Expanded(
                  child: _photoCaptured && _latestPhoto != null
                      ? Image.file(File(_latestPhoto!.path))
                      : CameraPreview(_controller!),
                );
              } else {
                return Center(child: CircularProgressIndicator());
              }
            },
          ),
          _photoCaptured
              ? Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton('Выйти', () {
                  Navigator.pop(context);
                }),
                _buildControlButton('Повтор', () {
                  _capturePhoto();
                }),
                _buildControlButton('ОК', () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreviewScreen(capturedPhotos: _capturedPhotos, title: widget.title,),
                    ),
                  );
                }),
                _buildControlButton('ОК+1', () {
                  setState(() {
                    _photoCaptured = false; // Сбрасываем состояние фото
                    _initializeCamera(); // Снова инициализируем камеру
                  });
                }),
              ],
            ),
          )
              : ElevatedButton(
            onPressed: _capturePhoto,
            child: Icon(Icons.camera_alt),
          ),
        ],
      )
          : Center(child: Text('Запрос разрешений на камеру...')),
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return Column(
      children: [
        TextButton(
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(fontSize: 16)),

        ),
      ],
    );
  }
}