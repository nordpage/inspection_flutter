// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapResult _$MapResultFromJson(Map<String, dynamic> json) => MapResult(
      address: json['address'] as String?,
      clientFio: json['client_fio'] as String,
      isUpload: (json['is_upload'] as num).toInt(),
      uploadMsg: json['upload_msg'] as String,
      documents: (json['documents'] as List<dynamic>?)
          ?.map((e) => Documents.fromJson(e as Map<String, dynamic>))
          .toList(),
      sections: (json['data'] as List<dynamic>?)
          ?.map((e) => MapSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MapResultToJson(MapResult instance) => <String, dynamic>{
      'address': instance.address,
      'client_fio': instance.clientFio,
      'is_upload': instance.isUpload,
      'upload_msg': instance.uploadMsg,
      'documents': instance.documents?.map((e) => e.toJson()).toList(),
      'data': instance.sections?.map((e) => e.toJson()).toList(),
    };
