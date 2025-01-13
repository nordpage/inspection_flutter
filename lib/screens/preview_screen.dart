import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/map_content.dart';
import '../server/api_service.dart';
import '../services/database_service.dart';
import '../provider/shared_preferences_provider.dart';

class PreviewScreen extends StatefulWidget {
  final String title;
  final int sectionId;
  final List<File> capturedPhotos;

  PreviewScreen({
    required this.title,
    required this.sectionId,
    required this.capturedPhotos,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final DatabaseService _dbService = DatabaseService();
  late ApiService _apiService;
  List<MapContent> _photoContents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    final sharedPreferencesProvider =
    Provider.of<SharedPreferencesProvider>(context, listen: false);
    _apiService = ApiService(sharedPreferencesProvider);

    _logCapturedPhotos();
    _loadContents();
  }

  void _logCapturedPhotos() {
    print("Captured Photos:");
    widget.capturedPhotos.forEach((photo) {
      final file = File(photo.path);
      if (file.existsSync()) {
        print("Файл существует: ${photo.path}");
      } else {
        print("Файл не найден: ${photo.path}");
      }
    });
  }

  Future<void> _loadContents() async {
    final contents = await _dbService.getContentsForSection(widget.sectionId);
    setState(() {
      _photoContents = contents;
      _isLoading = false;
    });
  }

  Future<void> _deletePhoto(MapContent photo) async {
    try {
      await _dbService.deleteContent(photo.id!);
      final file = File(photo.fileName!);
      if (file.existsSync()) {
        file.deleteSync();
      }
      _loadContents();
    } catch (e) {
      print('Ошибка удаления фото: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(8.0),
              itemCount: _photoContents.isNotEmpty
                  ? _photoContents.length
                  : widget.capturedPhotos.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8.0,
                mainAxisSpacing: 8.0,
              ),
              itemBuilder: (context, index) {
                if (_photoContents.isNotEmpty) {
                  final photoContent = _photoContents[index];
                  final file = File(photoContent.fileName!);
                  return _buildPhotoItem(file, photoContent);
                } else {
                  final file = widget.capturedPhotos[index];
                  return _buildPhotoItem(file, null);
                }
              },
            ),
          ),
          ExpansionTile(
            title: Text("Обозначения"),
            children: <Widget>[
              ListTile(
                leading: Icon(Icons.access_time, color: Colors.grey),
                title: Text('Фотографии еще не направлены на проверку'),
              ),
              ListTile(
                leading: Icon(Icons.check_circle_outline,
                    color: Colors.green),
                title: Text('Фотографии успешно отправлены'),
              ),
              ListTile(
                leading: Icon(Icons.error_outline, color: Colors.red),
                title: Text('Ошибка отправки фотографий'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoItem(File file, MapContent? content) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0), // Скругление углов
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Тень
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.0), // Скругление изображения
        child: Stack(
          children: [
            // Фотография
            Image.file(
              file,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            // Иконка статуса (слева сверху)
            Positioned(
              top: 8,
              left: 8,
              child: Icon(
                _getStatusIcon(content?.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            // Иконка удаления (справа сверху)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  if (content != null) _deletePhoto(content);
                },
                child: Icon(
                  Icons.delete,
                  color: Colors.red,
                  size: 20,
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
        return Icons.access_time; // Часы
      case 1:
        return Icons.check_circle_outline; // Галочка
      case -1:
        return Icons.error_outline; // Ошибка
      default:
        return Icons.access_time; // Вопрос
    }
  }

  Color _getStatusColor(int? status) {
    switch (status) {
      case 0:
        return Colors.grey; // Не отправлено
      case 1:
        return Colors.green; // Успешно
      case -1:
        return Colors.red; // Ошибка
      default:
        return Colors.blue;
    }
  }
}