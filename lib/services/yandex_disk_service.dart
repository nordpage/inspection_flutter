import 'dart:io';

import 'package:dio/dio.dart';

class YandexDiskService {
  late  Dio _dio;
  final String _baseUrl = 'https://storage.yandexcloud.net/priemkabucket/';

  YandexDiskService(String accessKey, String secretKey) {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      headers: {
        'Authorization': 'Bearer $accessKey',
        'X-Cloud-Secret-Key': secretKey,
      },
      connectTimeout: Duration(seconds: 30),
      receiveTimeout: Duration(seconds: 30),
      validateStatus: (status) => status! < 500,
    ));

    _dio.interceptors.add(InterceptorsWrapper(
        onError: (error, handler) {
          if (error.type == DioExceptionType.connectionTimeout) {
            return handler.next(DioException(
              requestOptions: error.requestOptions,
              error: 'Timeout при подключении к Yandex.Cloud',
            ));
          }
          return handler.next(error);
        }
    ));
  }

  Future<String> uploadVideo(File file, String fileName, {
    void Function(int sent, int total)? onProgress,
  }) async {
    try {
      // Загружаем файл целиком в память перед отправкой
      final bytes = await file.readAsBytes();

      final response = await _dio.put(
        fileName,
        data: bytes,
        options: Options(
          headers: {
            'Content-Type': 'video/mp4',
          },
        ),
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return '$_baseUrl$fileName';
      }
      throw Exception('Ошибка загрузки: ${response.statusCode}');
    } catch (e) {
      throw Exception('Ошибка при загрузке видео: $e');
    }
  }
}