// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_section.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MapSection _$MapSectionFromJson(Map<String, dynamic> json) => MapSection(
      id: (json['id'] as num).toInt(),
      n: (json['n'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String,
      url: json['url'] as String?,
      minPhoto: (json['min_photo'] as num?)?.toInt(),
      helpList: (json['help_list'] as List<dynamic>?)
          ?.map((e) => HelpResult.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$MapSectionToJson(MapSection instance) =>
    <String, dynamic>{
      'id': instance.id,
      'n': instance.n,
      'name': instance.name,
      'description': instance.description,
      'url': instance.url,
      'min_photo': instance.minPhoto,
      'help_list': instance.helpList,
    };
