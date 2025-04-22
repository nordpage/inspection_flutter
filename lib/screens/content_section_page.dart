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

  const ContentSectionPage({
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
  Timer? _autoScrollTimer;
  VideoPlayerController? _videoController;
  late bool _isVideoSection;

  @override
  void initState() {
    super.initState();
    _isVideoSection = _isSectionVideo(widget.initialIndex);
    currentIndex = widget.initialIndex;
    currentSection = widget.sections[currentIndex];
    _pageController = PageController(viewportFraction: 0.8);
    _initializeCamera();

    if (widget.isVideo &&
        currentSection.helpList != null &&
        currentSection.helpList!.isNotEmpty &&
        currentSection.helpList!.first.url != null) {
      _initializeVideoPlayer();
    }

    if (!widget.isVideo) {
      _startAutoScroll();
    }
  }

  bool _isSectionVideo(int index) {
    bool isVideo = widget.sections[index].name?.toLowerCase() == "видео";
    return isVideo;
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_pageController.page ?? 0).toInt() + 1;
        if (nextPage < currentSection.helpList!.length) {
          _pageController.animateToPage(
            nextPage,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeIn,
          );
        }
      }
    });
  }

  Future<void> _initializeVideoPlayer() async {
    if (currentSection.helpList != null &&
        currentSection.helpList!.isNotEmpty &&
        currentSection.helpList!.first.url != null) {
      await _videoController?.dispose();
      _videoController = VideoPlayerController.network(
        currentSection.helpList!.first.url!,
      );

      await _videoController!.initialize();
      if (mounted) setState(() {});
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (mounted) {
        setState(() {
          cameraDescription = cameras!.first;
        });
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _navigateToCamera() async {
    if (cameras == null || cameras!.isEmpty) {
      debugPrint('Camera is not available');
      return;
    }

    final photo = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CameraCaptureScreen(
          camera: cameraDescription,
          title: currentSection.name!,
          sectionId: currentSection.id!,
        ),
      ),
    );

    if (photo != null && mounted) {
      setState(() {
        capturedPhotos.add(photo);
      });
    }
  }

  Future<void> _goToNextSection() async {
    if (currentIndex < widget.sections.length - 1) {
      _autoScrollTimer?.cancel();
      await _videoController?.dispose();

      setState(() {
        currentIndex++;
        currentSection = widget.sections[currentIndex];
        _isVideoSection = _isSectionVideo(currentIndex);
        _videoController = null;
      });

      if (_isVideoSection) {
        await _initializeVideoPlayer();
      } else {
        _startAutoScroll();
      }
    }
  }

  Future<void> _goToPreviousSection() async {
    if (currentIndex > 0) {
      _autoScrollTimer?.cancel();
      await _videoController?.dispose();

      setState(() {
        currentIndex--;
        currentSection = widget.sections[currentIndex];
        _isVideoSection = _isSectionVideo(currentIndex);
        _videoController = null;
      });

      if (_isVideoSection) {
        await _initializeVideoPlayer();
      } else {
        _startAutoScroll();
      }
    }
  }

  Widget _buildCircleButton({
    required VoidCallback? onPressed,
    required IconData icon,
    double size = 32,
  }) {
    return SizedBox(
      width: 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0f7692),
          shape: const CircleBorder(),
          padding: const EdgeInsets.all(16),
        ),
        child: Icon(icon, size: size),
      ),
    );
  }

  Widget _endButton(bool isVideo) {
    return isVideo
        ? const SizedBox(width: 64, height: 64)
        : _buildCircleButton(
      onPressed: currentIndex < widget.sections.length - 1
          ? _goToNextSection
          : null,
      icon: Icons.arrow_forward,
    );
  }

  Widget _buildStatusIndicator() {
    if (widget.documents == null) return const SizedBox.shrink();

    var document = widget.documents!.firstWhere(
          (doc) => doc.mapPhotoId == currentSection.id,
      orElse: () => Document(
        id: 0,
        status: null,
        statusText: '',
        mapPhotoId: 0,
      ),
    );

    if (document.status == null) return const SizedBox.shrink();

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
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: color)),
        ],
      ),
    );
  }

  Widget _buildPhotoPageView(bool isVideo) {
    if (!isVideo &&
        currentSection.helpList != null &&
        currentSection.helpList!.isNotEmpty) {
      return Container(
        height: 280,
        margin: const EdgeInsets.symmetric(vertical: 16.0),
        child: PageView.builder(
          controller: _pageController,
          itemCount: currentSection.helpList!.length,
          itemBuilder: (context, index) {
            var helpItem = currentSection.helpList![index];
            return Column(
              children: [
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.network(
                        helpItem.url ?? '',
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(Icons.error_outline, color: Colors.red),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (helpItem.description?.isNotEmpty ?? false)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
                    child: Text(
                      helpItem.description ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.red,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            );
          },
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildVideoPlayer(bool isVideo) {
    if (!isVideo || _videoController == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatusIndicator(),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.4,
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          VideoProgressIndicator(
            _videoController!,
            allowScrubbing: true,
            colors: VideoProgressColors(
              playedColor: const Color(0xFF0f7692),
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
                  color: const Color(0xFF0f7692),
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
                icon: const Icon(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    bool _isVideo = _isSectionVideo(currentIndex);
    return Scaffold(
      appBar: AppBar(
        title: Text(currentSection.name ?? 'Детали'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _isVideo? _buildVideoPlayer(_isVideo) : _buildPhotoPageView(_isVideo),
            if (!_isVideo && capturedPhotos.isNotEmpty)
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
              padding: const EdgeInsets.all(16.0),
              child: Text(
                currentSection.description ?? 'Описание отсутствует',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCircleButton(
                    onPressed: currentIndex > 0 ? _goToPreviousSection : null,
                    icon: Icons.arrow_back,
                  ),
                  _buildCircleButton(
                    onPressed: _isVideo
                        ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoCaptureScreen(
                            sectionId: currentSection.id!,
                          ),
                        ),
                      );
                    }
                        : _navigateToCamera,
                    icon: _isVideo ? Icons.videocam : Icons.add_a_photo,
                  ),
                  _endButton(_isVideo),
                ],
              ),
            ),
          ],
        ),
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
}