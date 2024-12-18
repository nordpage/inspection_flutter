import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:inspection/screens/video_preview_screen.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/utils.dart';

class VideoCaptureScreen extends StatefulWidget {
  static const routeName = '/video-capture';
  @override
  State<VideoCaptureScreen> createState() => _VideoCaptureScreenState();
}

class _VideoCaptureScreenState extends State<VideoCaptureScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isLoading = true;
  bool _isRecording = false;
  Timer? _timer;
  Duration _recordingDuration = Duration.zero;

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

        final randomHash = getRandomString(10);
        final appDir = (await getExternalStorageDirectories(type: StorageDirectory.documents))?.first;
        final fileName = 'video_${randomHash}.mp4';
        final savedPath = '${appDir!.path}/$fileName';
        debugPrint(savedPath);

        if (!mounted) return;

        final file = await File(videoFile.path).copy(savedPath);

        debugPrint("Seconds: ${_recordingDuration.inSeconds.toString()}");

        if (_recordingDuration.inSeconds > 10) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoPreviewScreen(capturedVideo: file, duration: _recordingDuration,),
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
                child: CircularProgressIndicator(color: Color(0xFF0f7692))
            )
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
                        backgroundColor: _isRecording ? Colors.red : const Color(0xFF0f7692),
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