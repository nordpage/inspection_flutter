import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../models/map_content.dart';
import '../services/database_service.dart';
import '../utils/utils.dart';
import 'preview_screen.dart';

class CameraCaptureScreen extends StatefulWidget {
  final int sectionId;
  final CameraDescription camera;
  final String title;

  const CameraCaptureScreen({
    Key? key,
    required this.camera,
    required this.title,
    required this.sectionId,
  }) : super(key: key);

  @override
  _CameraCaptureScreenState createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends State<CameraCaptureScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  List<File> _savedPhotos = [];
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
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt >= 33) {
          // Для Android 13 и выше
          var cameraStatus = await Permission.camera.status;
          var photosStatus = await Permission.photos.status;

          print('Camera permission status: $cameraStatus');
          print('Photos permission status: $photosStatus');

          if (!cameraStatus.isGranted) {
            cameraStatus = await Permission.camera.request();
            print('New camera status after request: $cameraStatus');
          }

          if (!photosStatus.isGranted) {
            photosStatus = await Permission.photos.request();
            print('New photos status after request: $photosStatus');
          }

          if (cameraStatus.isGranted && photosStatus.isGranted) {
            setState(() {
              _isPermissionGranted = true;
              _initializeCamera();
            });
          } else {
            print('Final permissions - Camera: $cameraStatus, Photos: $photosStatus');
            _showPermissionError();
          }
        } else {
          // Для Android 12 и ниже
          var cameraStatus = await Permission.camera.status;
          var storageStatus = await Permission.storage.status;

          print('Camera permission status: $cameraStatus');
          print('Storage permission status: $storageStatus');

          if (!cameraStatus.isGranted) {
            cameraStatus = await Permission.camera.request();
            print('New camera status after request: $cameraStatus');
          }

          if (!storageStatus.isGranted) {
            storageStatus = await Permission.storage.request();
            print('New storage status after request: $storageStatus');
          }

          if (cameraStatus.isGranted && storageStatus.isGranted) {
            setState(() {
              _isPermissionGranted = true;
              _initializeCamera();
            });
          } else {
            print('Final permissions - Camera: $cameraStatus, Storage: $storageStatus');
            _showPermissionError();
          }
        }
      } else {
        // Для iOS или других платформ
        if (await Permission.camera.request().isGranted) {
          setState(() {
            _isPermissionGranted = true;
            _initializeCamera();
          });
        } else {
          _showPermissionError();
        }
      }
    } catch (e) {
      print('Error during permission request: $e');
      _showPermissionError();
    }
  }

  void _showPermissionError() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Камера и хранилище недоступны, предоставьте разрешения.'),
          duration: Duration(seconds: 3),
        ),
      );
      Navigator.pop(context);
    }
  }

  void _initializeCamera() {
    try {
      _controller = CameraController(
        widget.camera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller!.initialize().then((_) {
        if (!mounted) return;
        setState(() {});
      }).catchError((error) {
        print('Camera initialization error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка инициализации камеры: $error')),
          );
        }
      });
    } catch (e) {
      print('Camera setup error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка настройки камеры: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      print('Camera not initialized');
      return;
    }

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      setState(() {
        _latestPhoto = image;
        _photoCaptured = true;
      });
    } catch (e) {
      print('Error capturing photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при захвате фото: $e')),
        );
      }
    }
  }

  Future<void> _saveAndInsertPhotos() async {
    try {
      if (!await _checkStoragePermission()) {
        throw Exception('Storage permission denied');
      }

      final username = (await SharedPreferences.getInstance())
          .getString('username') ?? 'default_user';
      final baseDir = await getExternalStorageDirectory();
      final publicDir = Directory('${baseDir!.path}/Priemka/$username/photo');
      await publicDir.create(recursive: true);

      final lastPhoto = _savedPhotos.last;
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final newFilePath = '${publicDir.path}/$fileName';
      final savedFile = await lastPhoto.copy(newFilePath);

      final content = MapContent(
        id: DateTime.now().millisecondsSinceEpoch,
        fileName: savedFile.path,
        status: 0,
        hash: generateUniqueUid(savedFile.path),
        documentId: null,
        textInspection: null,
        statusInspection: null,
      );
      await _dbService.insertContentToSection(widget.sectionId, [content]);
    } catch (e) {
      print('Error saving photos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при сохранении фото: $e')),
        );
      }
    }
  }

  Future<bool> _checkStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        return await Permission.photos.request().isGranted;
      }
      return await Permission.storage.request().isGranted;
    }
    return true;
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isPermissionGranted
          ? Column(
        children: [
          Expanded(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (_photoCaptured && _latestPhoto != null) {
                    return Image.file(
                      File(_latestPhoto!.path),
                      fit: BoxFit.contain,
                      width: double.infinity,
                    );
                  }

                  final size = MediaQuery.of(context).size;
                  final scale = 1 / (_controller!.value.aspectRatio * size.aspectRatio);

                  return ClipRect(
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topCenter,
                      child: CameraPreview(_controller!),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
          ),
          Container(
            color: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: _photoCaptured
                ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  'Отмена',
                      () => Navigator.pop(context),
                ),
                _buildControlButton(
                  'Повтор',
                      () {
                    setState(() {
                      _photoCaptured = false;
                      _latestPhoto = null;
                    });
                  },
                ),
                _buildControlButton(
                  'ОК',
                      () async {
                    if (_latestPhoto != null && !_savedPhotos.any((photo) => photo.path == _latestPhoto!.path)) {
                      final file = File(_latestPhoto!.path);
                      _savedPhotos.add(file);
                      await _saveAndInsertPhotos();
                    }
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
                  },
                ),
                _buildControlButton(
                  'ОК + 1',
                      () async {
                    if (_latestPhoto != null) {
                      final file = File(_latestPhoto!.path);
                      if (!_savedPhotos.any((photo) => photo.path == file.path)) {
                        _savedPhotos.add(file);
                        await _saveAndInsertPhotos();
                      }
                      setState(() {
                        _photoCaptured = false;
                        _latestPhoto = null;
                      });
                    }
                  },
                ),
              ],
            )
                : Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(20),
                  backgroundColor: Colors.white,
                ),
                onPressed: _capturePhoto,
                child: const Icon(Icons.camera_alt,
                    size: 32,
                    color: Colors.black87),
              ),
            ),
          ),
        ],
      )
          : const Center(
        child: Text('Запрос разрешений на камеру и хранилище...'),
      ),
    );
  }

  Widget _buildControlButton(
      String label,
      VoidCallback onPressed,
      ) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
        ),
      ),
    );
  }
}