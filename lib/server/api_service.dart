import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import '../models/Keys.dart';
import '../models/login_response.dart';
import '../models/map_anketa.dart';
import '../provider/shared_preferences_provider.dart';
import '../models/osmotr_item.dart';
import '../models/questionnaire_sections.dart';
import '../models/map_result.dart';
import '../models/map_section.dart';
import '../services/firebase_service.dart';
import 'dart:typed_data' hide Uint8List;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ApiService {
  final String devUrl = 'https://dev-my.centr-i.ru/';
  final String prodUrl = 'https://my.centr-i.ru/';

  late Dio _devDio;
  late Dio _prodDio;
  final FirebaseService firebaseService = FirebaseService();
  final SharedPreferencesProvider sharedPreferencesProvider;

  ApiService(this.sharedPreferencesProvider) {
    _initializeDio();
  }

  void _initializeDio() {
    // Инициализация Dio для dev окружения
    _devDio = _createDioInstance(devUrl);

    // Инициализация Dio для prod окружения
    _prodDio = _createDioInstance(prodUrl);
  }

  Dio _createDioInstance(String baseUrl) {
    final dio = Dio()
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = Duration(seconds: 20)
      ..options.receiveTimeout = Duration(seconds: 30);

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

    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (HttpClient client) {
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
      return client;
    };

    return dio;
  }

  Future<Response> sendFile(
      String filePath,
      String type,
      String userName, {
        String? uid,
        int? mapPhotoId,
        String? b,
        String? l,
        void Function(double sent, double total)? onProgress,
      }) async {
    try {
      final formDataMap = <String, dynamic>{
        'uploadfile': await MultipartFile.fromFile(filePath),
        'type': type,
        'order': userName,
      };

      if (uid != null) formDataMap['uid'] = uid;
      if (mapPhotoId != null) formDataMap['map_photo_id'] = mapPhotoId.toString();
      if (b != null) formDataMap['B'] = b;
      if (l != null) formDataMap['L'] = l;

      final formData = FormData.fromMap(formDataMap);

      final response = await _devDio.post(
        'api/departures/uploadPhoto',
        options: Options(
          headers: {'Authorization': _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!)},
        ),
        data: formData,
        onSendProgress: onProgress != null ? (sent, total) {
          onProgress(sent.toDouble(), total.toDouble());
        } : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response;
      } else {
        throw Exception('Не удалось отправить файл');
      }
    } catch (e) {
      throw Exception('Ошибка при отправке файла: $e');
    }
  }


  // Остальные методы используют dev окружение по умолчанию
  Future<List<QuestionnaireSections>> getQuestionnaire() async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.get(
        'api/map_photo/anketa',
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

  Future<String> register(String body) async {
    try {
      final response = await _devDio.post(
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

  Future<MapResult> getMapWithBody(String body) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.post(
        'api/map_photo/map',
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

  Future<MapAnketa> getMapAnketa() async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.post(
        'api/map_photo/map/anketa',
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return MapAnketa.fromJson(response.data);
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
      final response = await _devDio.post(
        'api/map_photo/map',
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

  Future<dynamic> sendVideoUrl(String url) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.post(
        'api/map_photo/video_url',
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
      final response = await _devDio.post(
        'api/departures/removePhoto',
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
        throw Exception("FCM Token недоступен");
      }

      final response = await _devDio.post(
        'api/departures/login',
        options: Options(
          headers: {
            'Authorization': _getBasic(p1, p2),
          },
        ),
        queryParameters: {
          'token': fcmToken,
        },
      );

      if (response.statusCode == 200) {
        if (response.data['status'] == 'OK') {
          final loginResponse = LoginResponse.fromJson(response.data);
          onResponseListener('OK', response.statusCode!, loginResponse);
        } else {
          onResponseListener('FAILURE', -1, null);
        }
      } else {
        onResponseListener('FAILURE', -1, null);
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        onResponseListener('INTERNET', -1, null);
      } else {
        onResponseListener('FAILURE', -1, null);
      }
    } catch (e) {
      onResponseListener('FAILURE', -1, null);
    }
  }


  /// Получение списка времени
  Future<String> getTimeList(String token) async {
    try {
      final response = await _devDio.post(
        'api/departures/time_list',
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
  Future<List<OsmotrItem>> getOsmotrList(String d1, String d2) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.post(
        'api/departures/osmotr_list',
        options: Options(
          headers: {'Authorization': token},
        ),
        queryParameters: {'d1': d1, 'd2': d2},
      );

      if (response.statusCode == 200) {
        // Проверяем структуру ответа
        if (response.data['status'] == 'OK' && response.data['data'] != null) {
          List<dynamic> data = response.data['data']; // Берем массив из поля 'data'
          return data.map((item) => OsmotrItem.fromJson(item)).toList();
        } else {
          throw Exception('Некорректный статус ответа или отсутствуют данные');
        }
      } else {
        throw Exception('Не удалось получить список осмотров');
      }
    } catch (e) {
      throw Exception('Ошибка при получении списка осмотров: $e');
    }
  }

  Future<Keys> getKeys() async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);
    try {
      final response = await _devDio.post(
        '/api/map_photo/ya',
        options: Options(
          headers: {'Authorization': token},
        ),
      );

      if (response.statusCode == 200) {
        return Keys.fromJson(response.data);
      } else {
        throw Exception('Не удалось получить ключи');
      }
    } catch (e) {
      throw Exception('Ошибка при получении ключей: $e');
    }
  }

  /// Получение конкретного осмотра
  Future<MapSection> getOsmotr(String token, int id) async {
    try {
      final response = await _devDio.post(
        'api/departures/get_osmotr',
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
      final response = await _devDio.post(
        'api/departures/osmotr_cancel',
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
  Future<dynamic> referNew(Map<String, dynamic> data) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);

    try {
      final response = await _devDio.post(
        'api/departures/referal_new',
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

  String _getBasic(String p1, String p2) {
    final basicAuth = 'Basic ' + base64Encode(utf8.encode('$p1:$p2'));
    print('Basic Auth: $basicAuth');
    return basicAuth;
  }


  Future<void> cancelReferOrder(int orderId) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);

    try {
      final response = await _devDio.post(
        '/api/departures/osmotr_cancel',
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'id': orderId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при отмене заказа: ${response.data}');
      }
    } catch (e) {
      throw Exception('Ошибка при отмене заказа: $e');
    }
  }

  /// Метод для обновления существующего заказа рефералом
  Future<Map<String, dynamic>> updateReferOrder(Map<String, dynamic> orderData) async {
    String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);

    try {
      final response = await _devDio.post(
        'api/departures/referal_update',
        options: Options(
          headers: {
            'Authorization': token,
            'Content-Type': 'application/json',
          },
        ),
        data: orderData,
      );

      if (response.statusCode != 200) {
        throw Exception('Ошибка при обновлении заказа: ${response.data}');
      }

      return response.data;
    } catch (e) {
      throw Exception('Ошибка при обновлении заказа: $e');
    }
  }

  Future<Response> uploadOrderPhoto(
      String orderId, File photo, int typeSector,
      {String? uid}) async {
    try {
      // Устанавливаем заголовок авторизации
      String token = _getBasic(sharedPreferencesProvider.username!, sharedPreferencesProvider.password!);

      // Формируем базовый URL: например, departures/uploadPhoto?type=photos&order={orderId}
      String url = 'departures/uploadPhoto?type=photos&order=$orderId';
      if (uid != null && uid.isNotEmpty) {
        url += "&uid=$uid";
      }
      url += "&sector=$typeSector";

      // Определяем строку-сектор по типу
      Map<int, String> sectorNames = {
        1: "Дом снаружи ",
        2: "Дом изнутри ",
        3: "Квартира ",
      };
      String sectorName = sectorNames[typeSector] ?? "";

      // Получаем базовое имя исходного файла (без расширения)
      String originalBaseName = photo.path.split('/').last.split('.').first;
      String newFileName = "$sectorName$originalBaseName";

      // Обрабатываем изображение и сохраняем его как новый JPEG-файл
      File processedFile = await _processAndSaveImage(
        originalFile: photo,
        newFileName: newFileName,
        rotateAngle: 0, // Если требуется поворот, задайте, например, 90
        targetWidth: 1080,
        quality: 80,
      );

      // Формируем окончательное имя файла для отправки (например, последний сегмент пути)
      String finalFileName = processedFile.path.split('/').last;

      // Создаем FormData с файлом (имя поля – "uploadfile")
      FormData formData = FormData.fromMap({
        "uploadfile": await MultipartFile.fromFile(processedFile.path,
            filename: finalFileName),
      });

      // Отправляем POST-запрос на сервер
      Response response = await _devDio.post(url, options: Options(
        headers: {
          'Authorization': token,
          'Content-Type': 'application/json',
        },
      ), data: formData);

      // После успешной отправки удаляем временный обработанный файл
      await processedFile.delete();

      // Проверяем статус ответа
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Ошибка при загрузке фото: ${response.data}');
      }
      return response;
    } catch (e) {
      throw Exception("Ошибка при загрузке фото: $e");
    }
  }

  Future<File> _processAndSaveImage({
    required File originalFile,
    required String newFileName,
    int targetWidth = 1080,
    int quality = 80,
    int rotateAngle = 0,
  }) async {
    // Чтение байтов исходного файла как List<int>
    List<int> imageBytes = await originalFile.readAsBytes();

    // Декодирование изображения (функция decodeImage принимает List<int>)
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception('Не удалось декодировать изображение');
    }

    // Если нужен поворот, выполняем его
    img.Image processedImage = rotateAngle != 0
        ? img.copyRotate(originalImage, rotateAngle)
        : originalImage;

    // Изменяем размер изображения до targetWidth с сохранением пропорций
    processedImage = img.copyResize(processedImage, width: targetWidth);

    // Кодирование в JPEG с заданным качеством
    List<int> jpgBytes = img.encodeJpg(processedImage, quality: quality);

    // Получаем директорию для сохранения (например, documents)
    Directory directory = await getApplicationDocumentsDirectory();
    String newPath = '${directory.path}/$newFileName.jpg';

    // Создаем новый файл и записываем JPEG-данные
    File newFile = File(newPath);
    await newFile.writeAsBytes(jpgBytes);
    return newFile;
  }
}