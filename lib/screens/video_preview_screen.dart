import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File capturedVideo;
  final Duration duration;

  const VideoPreviewScreen({
    super.key,
    required this.capturedVideo,
    required this.duration,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(widget.capturedVideo);
    await _videoController!.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Видео"),
        backgroundColor: const Color(0xFF0f7692),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            child: Column(
              children: [
                // Кнопка "примеры фото"
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF0f7692),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.videocam, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Примеры видео',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                // Видео с контролами
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _videoController?.value.isInitialized ?? false
                            ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        )
                            : const Center(child: CircularProgressIndicator()),
                      ),
                    ),

                    // Кнопки таймера и закрытия
                    if (_videoController?.value.isInitialized ?? false)
                      Positioned(
                        top: 8,
                        left: 24,
                        child: Icon(Icons.access_time, color: Colors.grey)
                      ),

                    Positioned(
                      top: 8,
                      right: 24,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),

                    // Кнопка play/pause
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0f7692),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: IconButton(
                        iconSize: 48,
                        color: Colors.white,
                        icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () {
                          setState(() {
                            _isPlaying = !_isPlaying;
                            _isPlaying
                                ? _videoController?.play()
                                : _videoController?.pause();
                          });
                        },
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