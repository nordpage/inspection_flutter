import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:geolocator/geolocator.dart';
import 'package:inspection/services/upload_progress.dart';

import '../models/map_content.dart';
import '../provider/shared_preferences_provider.dart';
import '../server/api_service.dart';
import '../utils/utils.dart';
import 'database_service.dart';

class PhotoUploadService {
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService;
  final SharedPreferencesProvider _prefsProvider;
  final _uploadController = StreamController<UploadProgress>.broadcast();
  Timer? _timer;
  bool _isRunning = false;

  Stream<UploadProgress> get uploadProgress => _uploadController.stream;

  PhotoUploadService(this._prefsProvider)
      : _apiService = ApiService(_prefsProvider);

  Future<void> start() async {
    if (_isRunning) return;
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _processUploads());
    await _processUploads();
  }

  /// Процесс загрузки файлов в цикле
  Future<void> _processUploads() async {
    try {
      final contents = await _dbService.getPendingContents();
      debugPrint('contents: $contents');
      if (contents.isEmpty) {
        _stopUploading();
        return;
      }

      int total = contents.length;
      int current = 0;

      for (var content in contents) {
        if (!_isRunning) break;

        current++;

        _uploadController.add(UploadProgress(
          current: current,
          total: total,
          fileName: content.fileName ?? '',
        ));

        await _uploadContent(content);
      }

      // Останавливаем загрузку, если все файлы загружены
      _stopUploading();
    } catch (e) {
      _uploadController.addError(e);
    }
  }

  /// Загрузка файла на сервер
  Future<void> _uploadContent(MapContent content) async {
    try {
      final location = await _getLocation();
      final uid = content.hash ?? generateUniqueUid(content.fileName);

      await _dbService.updateUid(content.id!, uid);

      final file = File(content.fileName!);

      final Response response = await _apiService.sendFile(
        file.path,
        'photos',
        _prefsProvider.username ?? '',
        uid: uid,
        mapPhotoId: content.sectionId,
        b: location?.latitude.toString(),
        l: location?.longitude.toString(),
        onProgress: (sent, total) {
          _uploadController.add(UploadProgress(
            current: 1,
            total: 1,
            fileName: content.fileName!,
          ));
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final Map<String, dynamic> responseData = response.data;
        String status = responseData['status'] ?? '';
        if (status == 'OK') {
          await _dbService.updateContentStatus(responseData["document_id"], 1);
        }
      }
    } catch (e) {
      await _dbService.updateContentStatus(content.id!, -1);
      _uploadController.addError(e);
    }
  }

  /// Получение GPS-координат
  Future<Position?> _getLocation() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  void _stopUploading() {
    _isRunning = false;
    _timer?.cancel();
  }

  void dispose() {
    _stopUploading();
    _uploadController.close();
  }
}