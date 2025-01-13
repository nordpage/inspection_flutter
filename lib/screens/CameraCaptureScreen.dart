import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/map_content.dart';
import '../services/database_service.dart';
import '../utils/utils.dart';
import 'preview_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  final int sectionId;
  final CameraDescription camera;
  final String title;

  CameraCaptureScreen({
    required this.camera,
    required this.title,
    required this.sectionId,
  });

  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<File> _savedPhotos = []; // Сохраненные фото
  bool _isPermissionGranted = false;
  bool _photoCaptured = false;
  XFile? _latestPhoto;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.camera.request().isGranted &&
        await Permission.storage.request().isGranted) {
      setState(() {
        _isPermissionGranted = true;
        _initializeCamera();
      });
    } else {
      _showPermissionError();
    }
  }

  void _showPermissionError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Камера и хранилище недоступны, предоставьте разрешения.'),
      ),
    );
    Navigator.pop(context);
  }

  void _initializeCamera() {
    _controller = CameraController(widget.camera, ResolutionPreset.high);
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
        _photoCaptured = true;
      });
    } catch (e) {
      print('Ошибка при захвате фото: $e');
    }
  }

  Future<void> _saveAndInsertPhotos() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String username = prefs.getString('username') ?? 'default_user';
    final Directory publicDir =
    Directory('/storage/emulated/0/Priemka/$username/photo');

    if (!await publicDir.exists()) {
      await publicDir.create(recursive: true);
    }

    for (var xfile in _savedPhotos.map((file) => File(file.path))) {
      // Сохранение фото в общедоступную папку
      final String fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newFilePath = '${publicDir.path}/$fileName';
      final File savedFile = await xfile.copy(newFilePath);

      // Вставка данных о фото в базу данных
      final content = MapContent(
        id: DateTime.now().millisecondsSinceEpoch,
        fileName: savedFile.path,
        status: 0, // NOT_SENT
        documentId: null,
        textInspection: null,
        statusInspection: null,
      );
      await _dbService.insertContentToSection(widget.sectionId, [content]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Камера')),
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
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          _photoCaptured
              ? Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton('Выйти', () {
                Navigator.pop(context);
              }),
              _buildControlButton('Повтор', () {
                _capturePhoto();
              }),
              _buildControlButton('ОК', () async {
                if (_latestPhoto != null) {
                  final file = File(_latestPhoto!.path);
                  _savedPhotos.add(file); // Добавляем в список
                  await _saveAndInsertPhotos();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PreviewScreen(
                        capturedPhotos: _savedPhotos,
                        title: widget.title,
                        sectionId: widget.sectionId,
                      ),
                    ),
                  );
                }
              }),
            ],
          )
              : ElevatedButton(
            onPressed: _capturePhoto,
            child: const Icon(Icons.camera_alt),
          ),
        ],
      )
          : const Center(
        child: Text('Запрос разрешений на камеру и хранилище...'),
      ),
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}