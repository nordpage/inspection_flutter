import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/map_content.dart';
import '../provider/client_provider.dart';
import '../services/database_service.dart';
import '../provider/shared_preferences_provider.dart';
import 'content_section_page.dart';

class PreviewScreen extends StatefulWidget {
  final String title;
  final int sectionId;
  final List<File> capturedPhotos;


  PreviewScreen({
    Key? key,
    required this.title,
    required this.sectionId,
    required this.capturedPhotos,
  }) : super(key: key);

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final DatabaseService _dbService = DatabaseService();
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
    _initializePhotos();
  }

  Future<void> _initializePhotos() async {
    try {
      _photoContents = await _dbService.getContentsForSection(widget.sectionId);

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      print('Ошибка инициализации фото: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePhoto(MapContent photo) async {
    try {
      await _dbService.deleteContent(photo.id!);
      final section = clientProvider.mapResult!.sections!
          .firstWhere((s) => s.id == widget.sectionId);
      section.contentList = await _dbService.getContentsForSection(widget.sectionId);
      clientProvider.updateData();
      await clientProvider.getMap();

      setState(() {
        _photoContents.remove(photo);
      });

      if (_photoContents.isEmpty) {
        int index = clientProvider.mapResult!.sections!
            .indexWhere((element) => element.id == widget.sectionId);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ContentSectionPage(
              sections: clientProvider.mapResult!.sections!,
              initialIndex: index,
              documents: clientProvider.mapResult!.documents,
              isVideo: false,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ошибка при удалении фото')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(
          onPressed: () async {
            await clientProvider.getMap();
            Navigator.of(context).popUntil(
                    (route) => route.isFirst
            );
          },
        ),
        actions: [
          _isUploading ?
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
            ) :
              IconButton(onPressed: () {

              }, icon: const Icon(Icons.home))

        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => ContentSectionPage(
                  sections: clientProvider.mapResult!.sections!,
                  initialIndex: clientProvider.mapResult!.sections!.indexWhere(
                          (s) => s.id == widget.sectionId
                  ),
                  documents: clientProvider.mapResult!.documents,
                  isVideo: false,
                ),
              ),
            );
          },
          child: Text('К разделу'),
        ),
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
              child: Icon(
                _getStatusIcon(content.status),
                color: _getStatusColor(content.status),
                size: 24,
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
        return Icons.access_time;
      case 1:
        return Icons.check_circle_outline;
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
      default:
        return Colors.grey;
    }
  }
}