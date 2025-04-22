import 'dart:async';
import 'dart:io';

import 'package:inspection/services/upload_progress.dart';
import 'package:inspection/services/yandex_disk_service.dart';

import 'database_service.dart';

class YandexDiskUploader {
  static const String _baseUrl = 'https://storage.yandexcloud.net/priemkabucket/';

  final YandexDiskService _diskService;
  final StreamController<UploadProgress> _progressController;
  final DatabaseService _dbService;
  bool _isUploading = false;

  YandexDiskUploader(
      this._diskService,
      this._dbService,
      ) : _progressController = StreamController<UploadProgress>.broadcast();

  Stream<UploadProgress> get uploadProgress => _progressController.stream;

  Future<void> uploadVideo(File videoFile, String fileName, int sectionId) async {
    if (_isUploading) return;
    _isUploading = true;

    try {
      // Обновляем UI с начальным прогрессом
      _progressController.add(UploadProgress(
        current: 0,
        total: 100,
        fileName: fileName,
      ));

      final content = (await _dbService.getPendingVideoContents()).firstWhere(
            (content) => File(content.fileName!).path == videoFile.path,
        orElse: () => throw Exception('Видео не найдено в БД'),
      );

      final url = await _diskService.uploadVideo(
        videoFile,
        fileName,
      );

      // Обновляем URL и статус в БД
      await _dbService.updateContentStatus(content.id!, 1);
      await _dbService.updateVideoUrl(sectionId, url);

    } catch (e) {
      await _dbService.updateContentStatus(
          (await _dbService.getPendingVideoContents()).first.id!,
          -1
      );
      _progressController.addError(e);
      throw Exception('Ошибка загрузки видео: $e');
    } finally {
      _isUploading = false;
    }
  }

  void dispose() {
    _progressController.close();
  }
}