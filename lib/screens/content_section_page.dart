import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:inspection/models/document.dart';
import 'package:inspection/screens/video_capture_screen.dart';
import 'package:video_player/video_player.dart';
import '../models/map_section.dart';
import 'CameraCaptureScreen.dart';

class ContentSectionPage extends StatefulWidget {
  final List<MapSection> sections;
  final int initialIndex;
  final bool isVideo;
  final List<Document>? documents;

  ContentSectionPage({
    required this.sections,
    required this.initialIndex,
    this.isVideo = false,
    this.documents,
  });

  @override
  _ContentSectionPageState createState() => _ContentSectionPageState();
}

class _ContentSectionPageState extends State<ContentSectionPage> {
  late PageController _pageController;
  late int currentIndex;
  late MapSection currentSection;
  List<String> capturedPhotos = [];
  late CameraDescription cameraDescription;
  List<CameraDescription>? cameras;
  bool isVideo = false;
  Timer? _autoScrollTimer;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    currentSection = widget.sections[currentIndex];
    _pageController = PageController(viewportFraction: 0.8);
//    isVideo = currentSection.url!.contains('mp4');
    _initializeCamera();

    // Загрузка видео для видео-секции
    if (widget.isVideo && currentSection.helpList != null &&
        currentSection.helpList!.isNotEmpty &&
        currentSection.helpList!.first.url != null) {
      _initializeVideoPlayer(currentSection.helpList!.first.url!);
    }

    // Если не видео, запускаем автопрокрутку
    if (!widget.isVideo) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page ?? 0).toInt() + 1;
        if (nextPage < currentSection.helpList!.length) {
          _pageController.animateToPage(
            nextPage,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoController = VideoPlayerController.network(url);
    await _videoController!.initialize();
    setState(() {});
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      setState(() {
        cameraDescription = cameras!.first;
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _navigateToCamera() async {
    if (cameraDescription == null) {
      print('Camera is not available');
      return;
    }

    final photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCaptureScreen(camera: cameraDescription, title: currentSection.name!, sectionId: currentSection.id!,),
      ),
    );

    if (photo != null) {
      setState(() {
        capturedPhotos.add(photo);
      });
    }
  }

  void _goToNextSection() {
    if (currentIndex < widget.sections.length - 1) {
      setState(() {
        currentIndex++;
        currentSection = widget.sections[currentIndex];
        _videoController?.dispose();

        // Проверка на видео в следующей секции
        bool isNextSectionVideo = currentSection.name == "Видео";

        if (widget.isVideo || isNextSectionVideo) {
          if (currentSection.helpList != null &&
              currentSection.helpList!.isNotEmpty &&
              currentSection.helpList!.first.url != null) {
            _initializeVideoPlayer(currentSection.helpList!.first.url!);
          }
        }
      });
    }
  }

  void _goToPreviousSection() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        currentSection = widget.sections[currentIndex];
        _videoController?.dispose();

        // Проверка на видео в предыдущей секции
        bool isPreviousSectionVideo = currentSection.name == "Видео";

        if (widget.isVideo || isPreviousSectionVideo) {
          if (currentSection.helpList != null &&
              currentSection.helpList!.isNotEmpty &&
              currentSection.helpList!.first.url != null) {
            _initializeVideoPlayer(currentSection.helpList!.first.url!);
          }
        }
      });
    }
  }

  Widget _buildStatusIndicator() {
    if (widget.documents == null) return SizedBox.shrink();

    var document = widget.documents!.firstWhere(
          (doc) => doc.mapPhotoId == currentSection.id,
      orElse: () => Document(
        id: 0,
        status: null,
        statusText: '',
        mapPhotoId: 0,
      ),
    );

    if (document.status == null) return SizedBox.shrink();

    IconData icon;
    Color color;
    String text;

    switch (document.status) {
      case -1:
        icon = Icons.error_outline;
        color = Colors.red;
        text = 'Ошибка: ${document.statusText ?? 'Требуется исправление'}';
        break;
      case 0:
        icon = Icons.access_time;
        color = Colors.grey;
        text = 'На проверке';
        break;
      case 1:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        text = 'Проверено';
        break;
      default:
        return SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentSection.name ?? 'Детали'),
      ),
      body: Column(
        children: [
          if (!widget.isVideo && currentSection.helpList != null &&
              currentSection.helpList!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SizedBox(
                height: 300,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: currentSection.helpList!.length,
                  itemBuilder: (context, index) {
                    var helpItem = currentSection.helpList![index];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: Image.network(
                              helpItem.url ?? '',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        Text(
                            helpItem.description ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                color: Colors.red,
                                fontWeight: FontWeight.bold
                            ),
                            textAlign: TextAlign.center
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),

          if (widget.isVideo && _videoController != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIndicator(),
                  SizedBox(
                    height: 300,
                    child: AspectRatio(
                      aspectRatio: _videoController!.value.aspectRatio,
                      child: VideoPlayer(_videoController!),
                    ),
                  ),
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: Color(0xFF0f7692),
                      bufferedColor: Colors.grey.shade300,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _videoController!.value.isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Color(0xFF0f7692),
                        ),
                        onPressed: () {
                          setState(() {
                            _videoController!.value.isPlaying
                                ? _videoController!.pause()
                                : _videoController!.play();
                          });
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.replay,
                          color: Color(0xFF0f7692),
                        ),
                        onPressed: () {
                          _videoController!.seekTo(Duration.zero);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          if (!widget.isVideo && capturedPhotos.isNotEmpty)
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: capturedPhotos.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.file(
                        File(capturedPhotos[index]),
                        fit: BoxFit.contain,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              currentSection.description ?? 'Описание отсутствует',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),

          Spacer(),

          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0 ? _goToPreviousSection : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(Icons.arrow_back, size: 32),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0f7692),
                    shape: CircleBorder(),
                  ),
                ),
                if (widget.isVideo)
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoCaptureScreen(sectionId: currentSection.id!,),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Icons.videocam, size: 32),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0f7692),
                      shape: CircleBorder(),
                    ),
                  ),
                if (!widget.isVideo)
                  ElevatedButton(
                    onPressed: _navigateToCamera,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Icons.add_a_photo, size: 32),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0f7692),
                      shape: CircleBorder(),
                    ),
                  ),
                if (!widget.isVideo) // Убираем кнопку "вперед" для видео секции
                  ElevatedButton(
                    onPressed: currentIndex < widget.sections.length - 1
                        ? _goToNextSection
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(Icons.arrow_forward, size: 32),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0f7692),
                      shape: CircleBorder(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}