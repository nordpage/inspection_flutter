import 'dart:io';
import 'dart:typed_data';
import 'package:aws_client/s3_2006_03_01.dart';
import 'package:aws_client/src/shared/shared.dart'; // Для аутентификации
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class YandexUploader {
  static String accessKey = ""; // ⚠ Временное хранение ключей (убрать в продакшене)
  static String secretKey = ""; // ⚠ Временное хранение ключей
  static const String bucketName = "priemkabucket"; // Имя бакета
  static const String region = "ru-central1"; // Регион Yandex Cloud
  static const String endpoint = "https://storage.yandexcloud.net"; // Yandex Cloud S3

  late final S3 s3;

  YandexUploader(String accessKey, String secretKey) {
    s3 = S3(
      region: region,
      credentials: AwsClientCredentials(
        accessKey: accessKey,
        secretKey: secretKey,
      ),
      endpointUrl: endpoint,
      client: http.Client(), // Используем HTTP-клиент
    );
  }

  /// Загружает видео в Yandex Cloud
  Future<String?> uploadVideo(String filePath) async {
    File file = File(filePath);
    if (!await file.exists()) {
      debugPrint("❌ Файл не найден: $filePath");
      return null;
    }

    String fileName = path.basename(filePath);
    Uint8List fileBytes = await file.readAsBytes();

    try {
      debugPrint("📤 Загружаем файл: $fileName в Yandex Cloud...");

      final putResponse = await s3.putObject(
        bucket: bucketName,
        key: fileName,
        body: fileBytes,
        contentType: "video/mp4",
      );

      final videoUrl = "$endpoint/$bucketName/$fileName";
      debugPrint("✅ Видео загружено: $videoUrl\n$putResponse");
      return videoUrl;
    } catch (e) {
      debugPrint("❌ Ошибка загрузки: $e");
      return null;
    }
  }

  void close() {
    s3.close();
  }
}