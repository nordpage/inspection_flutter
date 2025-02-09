import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:provider/provider.dart';

import '../models/map_content.dart';
import '../server/api_service.dart';
import '../services/database_service.dart';
import '../provider/shared_preferences_provider.dart';

class VideoPreviewScreen extends StatefulWidget {
  final File capturedVideo;
  final Duration duration;
  final int sectionId;

  final String? uid;
  final String? b;
  final String? l;

  const VideoPreviewScreen({
    super.key,
    required this.capturedVideo,
    required this.duration,
    required this.sectionId,
    this.uid,
    this.b,
    this.l,
  });

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isPlaying = false;
  late final DatabaseService _dbService;
  late final ApiService _apiService;
  MapContent? _videoContent;
  late SharedPreferencesProvider prefsProvider;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    _apiService = ApiService(prefsProvider);

    _initializeVideoPlayer();
    _initializeVideoContent();
  }

  Future<void> _initializeVideoPlayer() async {
    _videoController = VideoPlayerController.file(widget.capturedVideo);
    await _videoController!.initialize();
    setState(() {});
  }

  Future<void> _initializeVideoContent() async {
    final content = MapContent(
      id: DateTime.now().millisecondsSinceEpoch,
      fileName: widget.capturedVideo.path,
      status: 0, // NOT_SENT
      documentId: null,
      textInspection: null,
      statusInspection: null,
    );
    await _dbService.insertContentToSection(widget.sectionId, [content]);

    setState(() {
      _videoContent = content;
    });

    _uploadVideo(content);
  }


  Future<void> _uploadVideo(MapContent photo) async {
    if (photo.fileName == null || !File(photo.fileName!).existsSync()) {
      print('Файл не существует: ${photo.fileName}');
      await _updatePhotoStatus(photo, -1); // ERROR
      return;
    }

    try {
      final response = await _apiService.sendFile(
        photo.fileName!,
        'video',
        '${prefsProvider.username}',
        uid: widget.uid,
        mapPhotoId: widget.sectionId,
        b: widget.b,
        l: widget.l,
      );

      await _updatePhotoStatus(photo, 1); // SENT
    } catch (e) {
      print('Ошибка загрузки видео: $e');
      await _updatePhotoStatus(photo, -1); // ERROR
    }
  }


  Future<void> _updatePhotoStatus(MapContent photo, int status) async {
    try {
      await _dbService.updateContentStatus(photo.id!, status);
      setState(() {
        photo.status = status;
      });
    } catch (e) {
      print('Ошибка обновления статуса: $e');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  IconData _getStatusIcon(int? status) {
    switch (status) {
      case 0:
        return Icons.access_time; // NOT_SENT
      case 1:
        return Icons.check_circle_outline; // SENT
      case -1:
        return Icons.error_outline; // ERROR
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.grey;
      case 1:
        return Colors.green;
      case -1:
        return Colors.red;
      default:
        return Colors.blue;
    }
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
              Positioned(
                top: 8,
                left: 24,
                child: Text(
                  _formatDuration(widget.duration),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ),
              Positioned(
                top: 8,
                right: 24,
                child: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 24,
                child: Icon(
                  _getStatusIcon(_videoContent?.status),
                  color: _getStatusColor(_videoContent?.status),
                ),
              ),
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
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}