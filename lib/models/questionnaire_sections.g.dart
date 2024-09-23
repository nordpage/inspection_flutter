// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'questionnaire_sections.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionnaireSections _$QuestionnaireSectionsFromJson(
        Map<String, dynamic> json) =>
    QuestionnaireSections(
      id: json['id'] as String?,
      n: (json['n'] as num?)?.toInt(),
      text: json['text'] as String?,
      minValue: (json['min_value'] as num?)?.toInt(),
      maxValue: (json['max_value'] as num?)?.toInt(),
      defValue: (json['def_value'] as num?)?.toInt(),
      value: (json['value'] as num?)?.toInt(),
    );

Map<String, dynamic> _$QuestionnaireSectionsToJson(
        QuestionnaireSections instance) =>
    <String, dynamic>{
      'id': instance.id,
      'n': instance.n,
      'text': instance.text,
      'min_value': instance.minValue,
      'max_value': instance.maxValue,
      'def_value': instance.defValue,
      'value': instance.value,
    };
