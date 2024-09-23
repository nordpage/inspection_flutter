import 'package:json_annotation/json_annotation.dart';

part 'questionnaire_sections.g.dart';

@JsonSerializable()
class QuestionnaireSections {
  String? id;
  int? n;
  String? text;
  @JsonKey(name: 'min_value')
  int? minValue;
  @JsonKey(name: 'max_value')
  int? maxValue;
  @JsonKey(name: 'def_value')
  int? defValue;
  int? value;

  QuestionnaireSections({
    this.id,
    this.n,
    this.text,
    this.minValue,
    this.maxValue,
    this.defValue,
    this.value,
  });

  factory QuestionnaireSections.fromJson(Map<String, dynamic> json) =>
      _$QuestionnaireSectionsFromJson(json);
  Map<String, dynamic> toJson() => _$QuestionnaireSectionsToJson(this);

  void update(QuestionnaireSections section) {
    this.n = section.n;
    this.text = section.text;
    this.minValue = section.minValue;
    this.maxValue = section.maxValue;
    this.defValue = section.defValue;
  }
}
