// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'help_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HelpResult _$HelpResultFromJson(Map<String, dynamic> json) => HelpResult(
      id: (json['id'] as num).toInt(),
      description: json['description'] as String?,
      url: json['url'] as String?,
      isVerticale: (json['is_verticale'] as num?)?.toInt(),
    );

Map<String, dynamic> _$HelpResultToJson(HelpResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'description': instance.description,
      'url': instance.url,
      'is_verticale': instance.isVerticale,
    };
