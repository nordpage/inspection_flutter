import 'dart:async';
import 'package:flutter/material.dart';
import 'package:inspection/models/map_result.dart';
import 'package:inspection/models/questionnaire_sections.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';
import '../models/document.dart';
import '../models/map_section.dart';
import '../server/api_service.dart';
import '../services/database_service.dart';
import '../services/photo_upload_service.dart';
import '../services/upload_progress.dart';
import '../services/upload_video_service.dart';
import '../utils/status_content.dart';

class ClientProvider with ChangeNotifier {
  final PhotoUploadService photoUploadService;
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService;

  List<QuestionnaireSections>? questionnaireSections;
  MapResult? mapResult;
  bool isLoading = false;
  String? errorMessage;
  String? uploadMessage;
  double progressPercentage = 0.0;
  Map<int, bool> filesToUpload = {};
  bool canSend = false;

  Map<String, double> uploadProgress = {};
  bool isUploading = false;
  StreamSubscription? _photoSubscription;
  StreamSubscription? _videoSubscription;
  Map<String, bool> uploadingStatus = {};

  ClientProvider(SharedPreferencesProvider prefsProvider) :
        _apiService = ApiService(prefsProvider),
        photoUploadService = PhotoUploadService(prefsProvider);

  Future<void> sendData() async {
    if (!canSend) return;
    isUploading = true;
    notifyListeners();

    try {
      // Получаем ключи перед отправкой данных
      final keys = await _apiService.getKeys();

      // Пример обработки видео
      final videoSection = mapResult!.sections!.firstWhere(
            (s) => s.name == "Видео" && s.contentList?.isNotEmpty == true,
        orElse: () => MapSection(),
      );

      if (videoSection.id != null &&
          videoSection.contentList?.isNotEmpty == true) {
        String? uploadedUrl = await YandexUploader(keys.accesskey, keys.secretkey)
            .uploadVideo(videoSection.contentList!.first.fileName!);
        await _apiService.sendVideoUrl(uploadedUrl!);
      }

      // Загрузка фото
      await photoUploadService.start();

      await getMap();
    } catch (e) {
      // Обработка ошибок
      throw Exception('Ошибка при отправке данных: $e');
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  void _updateUploadProgress(String sectionId, bool isUploading) {
    uploadingStatus[sectionId] = isUploading;
    notifyListeners();
  }

  Future<void> getMap() async {
    isLoading = true;
    notifyListeners();
    try {
      mapResult = await _apiService.getMap();

      if (mapResult?.sections != null) {
        for (var section in mapResult!.sections!) {
          final contents = await _dbService.getContentsForSection(section.id!);
          section.contentList = contents;
        }
      }

      await handleServerUpdate(mapResult!);
      await _checkFilesToUpload(mapResult!);
      updateData();
      isLoading = false;
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> handleServerUpdate(MapResult result) async {
    if (result.documents != null) {
      await updateContentStatuses(result.documents!);
    }
  }

  Future<void> updateContentStatuses(List<Document> documents) async {
    for (var doc in documents) {
      final contents = await _dbService.getContentsForSection(doc.mapPhotoId!);
      for (var content in contents) {
        int newStatus;
        switch (doc.status) {
          case -1:
            newStatus = StatusContent.FAILED;
            break;
          case 0:
            newStatus = content.status == StatusContent.UPLOADED
                ? StatusContent.UPLOADED
                : StatusContent.DEFAULT;
            break;
          case 1:
            newStatus = StatusContent.CHECKED;
            break;
          default:
            newStatus = StatusContent.DEFAULT;
        }

        await _dbService.updateContentStatus(
            content.id!,
            newStatus,
            statusText: doc.statusText
        );
      }
    }
    notifyListeners();
  }

  Icon getIcon(MapSection mapSection) {
    // Если минимальное количество фото равно 0, сразу возвращаем зеленую иконку
    if (mapSection.minPhoto == 0) {
      return Icon(Icons.check_circle_outline, color: Colors.green);
    }

    // Если фотографий меньше, чем требуется, возвращаем неактивную иконку
    if (mapSection.contentList == null ||
        mapSection.contentList!.length < (mapSection.minPhoto ?? 0)) {
      return Icon(Icons.circle_outlined, color: Colors.grey);
    }

    // Пытаемся найти документ с сервера, связанный с данной секцией
    final serverDoc = mapResult?.documents?.firstWhere(
          (doc) => doc.mapPhotoId == mapSection.id,
      orElse: () => Document(id: 0, status: null, statusText: null, mapPhotoId: 0),
    );

    // Если найден валидный документ (например, id != 0 и status не null), используем его статус
    if (serverDoc != null && serverDoc.id != 0 && serverDoc.status != null) {
      switch (serverDoc.status) {
        case -1:
          return Icon(Icons.error_outline, color: Colors.red);
        case 0:
          return Icon(Icons.check_circle_outline, color: Colors.grey);
        case 1:
          return Icon(Icons.check_circle_outline, color: Colors.green);
        default:
        // При неизвестном статусе можно вернуть дефолтную иконку
          return Icon(Icons.circle_outlined, color: Colors.grey);
      }
    }

    // Если серверный документ не найден или недействителен, проверяем наличие неотправленных фото
    bool hasUnsentPhotos = mapSection.contentList!.any((item) =>
    item.status == StatusContent.ADDED ||
        item.status == StatusContent.DEFAULT);
    if (hasUnsentPhotos) {
      return Icon(Icons.access_time, color: Colors.grey);
    }

    // Если ни один из условий не сработал, возвращаем дефолтную иконку
    return Icon(Icons.circle_outlined, color: Colors.grey);
  }

  Future<void> _checkFilesToUpload(MapResult mapresult) async {
    filesToUpload.clear();
    final contents = await _dbService.getAllPendingContents();
    for (var content in contents) {
      bool isUploaded = mapresult.documents?.any((doc) => doc.mapPhotoId == content.sectionId) == true;
      debugPrint('isUploaded: $isUploaded');
      if (content.sectionId != null && !isUploaded) {
        filesToUpload[content.sectionId!] = true;
      }
    }
  }

  void _updateProgress(String type, UploadProgress progress) {
    double percentage = progress.total > 0 ? progress.current / progress.total : 0.0;
    uploadProgress[type] = percentage;
    progressPercentage = uploadProgress.values.fold(0.0, (a, b) => a + b) / uploadProgress.length;
    notifyListeners();
  }

  void _handleUploadError(String type, dynamic error) {
    uploadProgress[type] = 0;
    errorMessage = 'Ошибка загрузки $type: ${error.toString()}';
    notifyListeners();
  }

  void _checkUploadComplete() {
    if (uploadProgress.values.every((p) => p >= 1.0)) {
      isUploading = false;
      getMap();
    }
  }

  void calculateProgress() {
    if (mapResult == null || mapResult!.sections == null || mapResult!.sections!.isEmpty) {
      progressPercentage = 0.0;
      return;
    }

    int totalSections = mapResult!.sections!.where((section) => section.minPhoto != 0).length;
    int validSectionsCount = 0;

    for (var section in mapResult!.sections!) {
      if (section.minPhoto == 0) continue;

      int minPhotos = section.minPhoto ?? 0;
      int uploadedPhotos = section.contentList?.where((content) =>
      content.status == StatusContent.DEFAULT ||
          content.status == StatusContent.ADDED
      ).length ?? 0;

      if ((section.contentList?.isNotEmpty ?? false) && uploadedPhotos >= minPhotos) {
        validSectionsCount++;
      }
    }

    double percentage = totalSections > 0 ? (validSectionsCount / totalSections) * 100 : 0.0;
    progressPercentage = double.parse(percentage.clamp(0.0, 100.0).toStringAsFixed(0));

    notifyListeners();
  }

  void checkCanSend() {
    if (mapResult == null || mapResult!.sections == null) {
      canSend = false;
      return;
    }

    // if (mapResult!.isUpload != 1) {
    //   canSend = false;
    //   uploadMessage = mapResult!.uploadMsg;
    //   return;
    // }

    uploadMessage = null;

    int totalSections = mapResult!.sections!.where((section) => section.minPhoto != 0).length;
    int validSectionsCount = 0;

    for (var section in mapResult!.sections!) {
      if (section.minPhoto == 0) continue;

      int minPhotos = section.minPhoto ?? 0;
      int uploadedPhotos = section.contentList?.where((content) =>
      content.status == StatusContent.DEFAULT ||
          content.status == StatusContent.ADDED
      ).length ?? 0;

      if ((section.contentList?.isNotEmpty ?? false) && uploadedPhotos >= minPhotos) {
        validSectionsCount++;
      }
    }

    canSend = totalSections > 0 && validSectionsCount == totalSections;
    debugPrint('canSend: $canSend totalSections: $totalSections validSectionsCount: $validSectionsCount');

    notifyListeners();
  }

  void updateData() {
    calculateProgress();
    checkCanSend();
    notifyListeners();
  }

  @override
  void dispose() {
    _photoSubscription?.cancel();
    _videoSubscription?.cancel();
    photoUploadService.dispose();
    super.dispose();
  }
}