// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_content.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapContent _$MapContentFromJson(Map<String, dynamic> json) => MapContent(
      uri: json['uri'] as String?,
      status: (json['status'] as num?)?.toInt(),
      type: (json['type'] as num?)?.toInt(),
      fileName: json['fileName'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lon: (json['lon'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$MapContentToJson(MapContent instance) =>
    <String, dynamic>{
      'uri': instance.uri,
      'status': instance.status,
      'type': instance.type,
      'fileName': instance.fileName,
      'lat': instance.lat,
      'lon': instance.lon,
    };
