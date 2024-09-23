import 'package:json_annotation/json_annotation.dart';

part 'map_content.g.dart';

@JsonSerializable()
class MapContent {
  final String? uri; // Может быть null
  final int? status; // Может быть null
  final int? type; // Может быть null
  final String? fileName; // Может быть null
  final double? lat; // Может быть null
  final double? lon; // Может быть null

  MapContent({
    this.uri, // Обрабатываем как nullable
    this.status, // Обрабатываем как nullable
    this.type, // Обрабатываем как nullable
    this.fileName, // Обрабатываем как nullable
    this.lat, // Обрабатываем как nullable
    this.lon, // Обрабатываем как nullable
  });

  factory MapContent.fromJson(Map<String, dynamic> json) =>
      _$MapContentFromJson(json);

  Map<String, dynamic> toJson() => _$MapContentToJson(this);
}
