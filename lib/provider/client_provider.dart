// provider/client_provider.dart

import 'package:flutter/material.dart';
import 'package:inspection/models/map_result.dart';
import 'package:inspection/models/questionnaire_sections.dart';
import '../server/api_service.dart';

class ClientProvider with ChangeNotifier {
  late ApiService? apiService;

  List<QuestionnaireSections>? questionnaireSections;
  MapResult? mapResult;
  bool isLoading = false;
  String? errorMessage;
  String? uploadMessage;

  double progressPercentage = 0.0;
  bool canSend = false;

  ClientProvider({required this.apiService});

  // Метод для обновления ApiService
  void updateApiService(ApiService newApiService) {
    apiService = newApiService;
    // Вы можете добавить дополнительную логику здесь, если необходимо
  }

  // Метод для получения данных карты
  Future<void> getMap() async {
    isLoading = true;
    notifyListeners();
    try {
      mapResult = await apiService!.getMap();
      calculateProgress();
      checkCanSend();
      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Метод для вычисления прогресса заполнения
  void calculateProgress() {
    if (mapResult == null || mapResult!.sections == null) {
      progressPercentage = 0.0;
      return;
    }

    int totalSections = mapResult!.sections!.length;
    int completedSections = mapResult!.sections!.where((section) {
      return (section.contentList?.length ?? 0) >= (section.minPhoto ?? 0);
    }).length;

    progressPercentage =
    totalSections > 0 ? completedSections / totalSections : 0.0;
  }

  // Метод для проверки возможности отправки данных
  void checkCanSend() {
    if (mapResult == null || mapResult!.sections == null) {
      canSend = false;
      return;
    }

    // Проверяем поле isUpload
    if (mapResult!.isUpload != 1) {
      canSend = false;
      uploadMessage = mapResult!.uploadMsg;
      return;
    } else {
      uploadMessage = null;
    }

    // Проверяем, заполнены ли все обязательные секции
    canSend = mapResult!.sections!.every((section) {
      return (section.contentList?.length ?? 0) >= (section.minPhoto ?? 0);
    });
  }

  // Метод для отправки данных на сервер
  Future<void> sendData() async {
    if (!canSend) {
      errorMessage = 'Заполните все обязательные категории.';
      notifyListeners();
      return;
    }

    isLoading = true;
    notifyListeners();

    try {
      // Реализуйте логику загрузки данных
      // Например, вызовите метод apiService.uploadData(mapResult)
    //  await apiService!.uploadData(mapResult!);

      isLoading = false;
      // Отображение уведомления об успешной отправке, если необходимо
      notifyListeners();
    } catch (e) {
      isLoading = false;
      errorMessage = 'Ошибка при отправке данных: $e';
      notifyListeners();
    }
  }

  // Метод для обновления данных после изменений
  void updateData() {
    calculateProgress();
    checkCanSend();
    notifyListeners();
  }
}