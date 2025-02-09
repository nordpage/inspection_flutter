import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/map_content.dart';
import '../provider/client_provider.dart';
import '../server/api_service.dart';
import '../services/database_service.dart';
import '../provider/shared_preferences_provider.dart';

class PreviewScreen extends StatefulWidget {
  final String title;
  final int sectionId;
  final List<File> capturedPhotos;

  final String? uid;
  final String? b;
  final String? l;

  PreviewScreen({
    Key? key,
    required this.title,
    required this.sectionId,
    required this.capturedPhotos,
    this.uid,
    this.b,
    this.l,
  }) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final DatabaseService _dbService = DatabaseService();
  late ApiService _apiService;
  List<MapContent> _photoContents = [];
  bool _isLoading = true;
  bool _isUploading = false;
  late SharedPreferencesProvider prefsProvider;
  late ClientProvider clientProvider;


  @override
  void initState() {
    super.initState();
    prefsProvider = Provider.of<SharedPreferencesProvider>(context, listen: false);
    clientProvider = Provider.of<ClientProvider>(context, listen: false);
    _apiService = ApiService(prefsProvider);
    _initializePhotos();
  }

  Future<void> _initializePhotos() async {
    try {
      _photoContents = await _dbService.getContentsForSection(widget.sectionId);

      if (widget.capturedPhotos.isNotEmpty) {
        await _processNewPhotos();
      }

      setState(() {
        _isLoading = false;
      });

      _uploadAllPhotos();
    } catch (e) {
      print('Ошибка инициализации фото: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processNewPhotos() async {
    for (var photo in widget.capturedPhotos) {
      if (!_photoContents.any((content) => content.fileName == photo.path)) {
        final content = MapContent(
          id: DateTime.now().millisecondsSinceEpoch,
          fileName: photo.path,
          status: 0, // NOT_SENT
          documentId: null,
          textInspection: null,
          statusInspection: null,
        );
        await _dbService.insertContentToSection(widget.sectionId, [content]);
        _photoContents.add(content);
      }
    }
  }

  Future<void> _uploadAllPhotos() async {
    if (_isUploading) return;

    setState(() {
      _isUploading = true;
    });

    try {
      for (var photo in _photoContents) {
        if (photo.status != 1) { // 1 - SENT
          await _uploadPhoto(photo);
        }
      }
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _uploadPhoto(MapContent photo) async {
    if (photo.fileName == null || !File(photo.fileName!).existsSync()) {
      print('Файл не существует: ${photo.fileName}');
      await _updatePhotoStatus(photo, -1); // ERROR
      return;
    }

    try {
      final response = await _apiService.sendFile(
        photo.fileName!,
        'photo',
        '${prefsProvider.username}',
        uid: widget.uid,
        mapPhotoId: widget.sectionId,
        b: widget.b,
        l: widget.l,
      );

      await _updatePhotoStatus(photo, 1); // SENT
    } catch (e) {
      print('Ошибка загрузки фото: $e');
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

  Future<void> _deletePhoto(MapContent photo) async {
    try {
      await _dbService.deleteContent(photo.id!);

      final file = File(photo.fileName!);
      if (file.existsSync()) {
        await file.delete();
      }

      setState(() {
        _photoContents.remove(photo);
      });
    } catch (e) {
      print('Ошибка удаления фото: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении фото')),
      );
    }
  }

  Future<void> _retryUpload(MapContent photo) async {
    await _uploadPhoto(photo);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          if (_isUploading)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _photoContents.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (context, index) {
                final photoContent = _photoContents[index];
                final file = File(photoContent.fileName!);
                return _buildPhotoItem(file, photoContent);
              },
            ),
          ),
          ExpansionTile(
            title: const Text("Обозначения"),
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.grey),
                title: const Text('Фотографии еще не отправлены'),
              ),
              ListTile(
                leading:
                const Icon(Icons.check_circle_outline, color: Colors.green),
                title: const Text('Фотографии успешно отправлены'),
              ),
              ListTile(
                leading:
                const Icon(Icons.error_outline, color: Colors.red),
                title: const Text('Ошибка отправки фотографий'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(File file, MapContent content) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0),
        child: Stack(
          children: [
            Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Иконка статуса
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: content.status == -1 ? () => _retryUpload(content) : null,
                child: Icon(
                  _getStatusIcon(content.status),
                  color: _getStatusColor(content.status),
                  size: 24,
                ),
              ),
            ),
            // Иконка удаления
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _deletePhoto(content),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getStatusIcon(int? status) {
    switch (status) {
      case 0:
        return Icons.access_time; // не отправлено
      case 1:
        return Icons.check_circle_outline; // отправлено
      case -1:
        return Icons.refresh; // ошибка, можно повторить
      default:
        return Icons.access_time;
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.grey;   // не отправлено
      case 1:
        return Colors.green;  // отправлено
      case -1:
        return Colors.red;    // ошибка
      default:
        return Colors.grey;
    }
  }
}