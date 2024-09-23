// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'documents.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Documents _$DocumentsFromJson(Map<String, dynamic> json) => Documents(
      id: (json['id'] as num).toInt(),
      status: (json['status'] as num).toInt(),
      statusText: json['status_text'] as String,
    );

Map<String, dynamic> _$DocumentsToJson(Documents instance) => <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'status_text': instance.statusText,
    };
