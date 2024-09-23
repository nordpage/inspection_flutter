import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/cupertino.dart';
import 'package:inspection/models/login_response.dart';
import 'package:inspection/provider/shared_preferences_provider.dart';

import '../models/questionnaire_sections.dart';
import '../models/map_result.dart';
import '../models/map_section.dart';
import '../services/firebase_service.dart';

class ApiService {
  final String baseUrl = 'https://dev-my.centr-i.ru/api/';
  final Dio dio = Dio();
  final FirebaseService firebaseService = FirebaseService();
  final SharedPreferencesProvider sharedPreferencesProvider;


  ApiService(this.sharedPreferencesProvider) {
    dio.options.baseUrl = baseUrl;
    dio.options.connectTimeout = Duration(seconds: 20);
    dio.options.receiveTimeout = Duration(seconds: 30);

    // Добавляем интерцептор для логирования запросов и ответов
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
      logPrint: (object) {
        print(object);
      },
    ));

    // Настройка адаптера для игнорирования некорректных сертификатов (для разработки)
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };
  }

  Future<List<QuestionnaireSections>> getQuestionnaire() async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await dio.get(
        'map_photo/anketa',
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data
            .map((item) => QuestionnaireSections.fromJson(item))
            .toList();
      } else {
        throw Exception('Не удалось загрузить анкету');
      }
    } catch (e) {
      throw Exception('Ошибка при загрузке анкеты: $e');
    }
  }

  Future<String> register(Map<String, Object> body) async {
    try {
      final response = await dio.post(
        'public/app_order_new',
        data: body,
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data.toString();
      } else {
        throw Exception('Не удалось зарегистрироваться');
      }
    } catch (e) {
      throw Exception('Ошибка при регистрации: $e');
    }
  }

  Future<MapResult> getMapWithBody(Map<String, Object> body, String token) async {
    try {
      final response = await dio.post(
        'map_photo/map',
        data: body,
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return MapResult.fromJson(response.data);
      } else {
        throw Exception('Не удалось получить карту с телом запроса');
      }
    } catch (e) {
      throw Exception('Ошибка при получении карты с телом запроса: $e');
    }
  }

  /// Получение карты без тела запроса
  Future<MapResult> getMap() async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await dio.post(
        'map_photo/map',
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return MapResult.fromJson(response.data);
      } else {
        throw Exception('Не удалось получить карту');
      }
    } catch (e) {
      throw Exception('$e');
    }
  }

  /// Отправка URL видео
  Future<dynamic> sendVideoUrl(String url, String token) async {
    try {
      final response = await dio.post(
        'map_photo/video_url',
        queryParameters: {
          'url': url,
        },
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // Здесь можно вернуть конкретный тип, если он известен
      } else {
        throw Exception('Не удалось отправить URL видео');
      }
    } catch (e) {
      throw Exception('Ошибка при отправке URL видео: $e');
    }
  }

  /// Удаление контента
  Future<dynamic> removeContent(int id, String token) async {
    try {
      final response = await dio.post(
        'departures/removePhoto',
        queryParameters: {
          'id': id,
        },
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return response.data; // Здесь можно вернуть конкретный тип, если он известен
      } else {
        throw Exception('Не удалось удалить контент');
      }
    } catch (e) {
      throw Exception('Ошибка при удалении контента: $e');
    }
  }

  /// Авторизация
  Future<void> login(
      String p1,
      String p2,
      Function(String status, int code, LoginResponse? response) onResponseListener,
      ) async {
    try {
      String? fcmToken = firebaseService.fcmToken;

      if (fcmToken == null) {
        throw Exception("FCM Token is not available");
      }

      // Log the FCM Token
      print('Using FCM Token: $fcmToken');

      final response = await dio.post(
        'departures/login',
        options: Options(
          headers: {
            'Authorization': _getBasic(p1, p2),
          },
        ),
        queryParameters: {
          'token': fcmToken,
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data['status'] == 'OK') {
          final loginResponse = LoginResponse.fromJson(response.data);
          onResponseListener('OK', response.statusCode!, loginResponse);
        } else {
          print('Login failed with server message: ${response.data}');
          onResponseListener('FAILURE', -1, null);
        }
      } else {
        print('Unexpected status code: ${response.statusCode}');
        onResponseListener('FAILURE', -1, null);
      }
    } on DioException catch (e) {
      print('DioException occurred: ${e.message}');
      print('DioException type: ${e.type}');
      print('DioException response data: ${e.response?.data}');
      onResponseListener('FAILURE', -1, null);
    } catch (e) {
      print('An exception occurred: $e');
      onResponseListener('FAILURE', -1, null);
    }
  }


  /// Получение списка времени
  Future<String> getTimeList(String token) async {
    try {
      final response = await dio.post(
        'departures/time_list',
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return response.data.toString(); // Здесь можно вернуть конкретный тип, если он известен
      } else {
        throw Exception('Не удалось получить список времени');
      }
    } catch (e) {
      throw Exception('Ошибка при получении списка времени: $e');
    }
  }

  /// Получение списка осмотров
  Future<List<MapSection>> getOsmotrList(String token, String d1, String d2) async {
    try {
      final response = await dio.post(
        'departures/osmotr_list',
        options: Options(
          headers: {'Authorization': token},
        ),
        queryParameters: {
          'd1': d1,
          'd2': d2,
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> data = response.data;
        return data.map((item) => MapSection.fromJson(item)).toList();
      } else {
        throw Exception('Не удалось получить список осмотров');
      }
    } catch (e) {
      throw Exception('Ошибка при получении списка осмотров: $e');
    }
  }

  /// Получение конкретного осмотра
  Future<MapSection> getOsmotr(String token, int id) async {
    try {
      final response = await dio.post(
        'departures/get_osmotr',
        options: Options(
          headers: {'Authorization': token},
        ),
        queryParameters: {
          'id': id,
        },
      );

      if (response.statusCode == 200) {
        return MapSection.fromJson(response.data);
      } else {
        throw Exception('Не удалось получить осмотр');
      }
    } catch (e) {
      throw Exception('Ошибка при получении осмотра: $e');
    }
  }

  /// Отмена заказа
  Future<String> cancelOrder(String token, int id) async {
    try {
      final response = await dio.post(
        'departures/osmotr_cancel',
        options: Options(
          headers: {'Authorization': token},
        ),
        queryParameters: {
          'id': id,
        },
      );

      if (response.statusCode == 200) {
        return response.data.toString(); // Здесь можно вернуть конкретный тип, если он известен
      } else {
        throw Exception('Не удалось отменить заказ');
      }
    } catch (e) {
      throw Exception('Ошибка при отмене заказа: $e');
    }
  }

  /// Создание нового реферала
  Future<dynamic> referNew(String token, Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        'departures/referal_new',
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data; // Здесь можно вернуть конкретный тип, если он известен
      } else {
        throw Exception('Не удалось создать реферал');
      }
    } catch (e) {
      throw Exception('Ошибка при создании реферала: $e');
    }
  }

  /// Отправка фотографии
  Future<Response> sendPhoto(String token, String filePath, String type, String order) async {
    try {
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
        'type': type,
        'order': order,
      });

      final response = await dio.post(
        'departures/uploadPhoto',
        options: Options(
          headers: {'Authorization': token},
        ),
        data: formData,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception('Не удалось отправить фотографию');
      }
    } catch (e) {
      throw Exception('Ошибка при отправке фотографии: $e');
    }
  }

  /// Вспомогательный метод для Basic Auth
  String _getBasic(String p1, String p2) {
    final basicAuth = 'Basic ' + base64Encode(utf8.encode('$p1:$p2'));
    print('Basic Auth: $basicAuth');
    return basicAuth;
  }
}
