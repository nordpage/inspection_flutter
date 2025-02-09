import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:inspection/screens/video_preview_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_content.dart';
import '../services/database_service.dart';
import '../utils/utils.dart';

class VideoCaptureScreen extends StatefulWidget {
  final int sectionId;
  static const routeName = '/video-capture';

  const VideoCaptureScreen({super.key, required this.sectionId});
  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isLoading = true;
  bool _isRecording = false;
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;

    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      final controller = CameraController(
        firstCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );

      await controller.initialize();

      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingDuration += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final XFile videoFile = await _controller!.stopVideoRecording();
        _stopTimer();

        if (!mounted) return;

        if (_recordingDuration.inSeconds > 7) {
          // Сохранение видео в директорию
          final savedFile = await _saveVideoToDocuments(videoFile);

          final content = MapContent(
            id: DateTime.now().millisecondsSinceEpoch,
            fileName: savedFile.path,
            status: 0, // NOT_SENT
            documentId: null,
            textInspection: null,
            statusInspection: null,
          );
          await _dbService.insertContentToSection(widget.sectionId, [content]);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(
                capturedVideo: savedFile,
                duration: _recordingDuration, sectionId: widget.sectionId,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Видео должно быть больше 7 минут'),
              backgroundColor: Color(0xFF0f7692),
            ),
          );
        }

        setState(() {
          _recordingDuration = Duration.zero;
        });
      } catch (e) {
        debugPrint('Error stopping video recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при сохранении видео'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      try {
        await _controller?.startVideoRecording();
        _startTimer();
      } catch (e) {
        debugPrint('Error starting video recording: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ошибка при начале записи'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _isRecording = !_isRecording);
  }

  Future<File> _saveVideoToDocuments(XFile videoFile) async {
    try {
      // Получение имени пользователя из SharedPreferences
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String username = prefs.getString('username') ?? 'default_user';

      // Получение пути к публичной директории
      final Directory? documentsDir = await getExternalStorageDirectory();
      if (documentsDir != null) {
        // Формирование пути с подпапками
        final String priemkaPath =
            '${documentsDir.path}/Priemka/$username/video';
        final Directory targetDir = Directory(priemkaPath);

        if (!await targetDir.exists()) {
          await targetDir.create(recursive: true);
        }

        final randomHash = getRandomString(10);

        final String newFilePath =
            '$priemkaPath/video_$randomHash.mp4';


        // Копирование видео в директорию
        final File newFile = await File(videoFile.path).copy(newFilePath);

        print('Видео сохранено: ${newFile.path}');

        return newFile;
      } else {
        throw Exception('Документ директория недоступна');
      }
    } catch (e) {
      print('Ошибка сохранения видео: $e');
      throw Exception('Ошибка сохранения видео');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String minutes = twoDigits(duration.inMinutes);
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Запись Видео"),
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(
                child: CircularProgressIndicator(color: Color(0xFF0f7692)))
          else
            CameraPreview(_controller!),
          if (!_isLoading)
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRecording)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _formatDuration(_recordingDuration),
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: _toggleRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isRecording
                            ? Colors.red
                            : const Color(0xFF0f7692),
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.videocam,
                        size: 32,
                      ),
                    )
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}