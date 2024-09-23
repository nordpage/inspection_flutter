import 'package:json_annotation/json_annotation.dart';

part 'help_result.g.dart';

@JsonSerializable()
class HelpResult {
  final int id;
  final String? description;
  final String? url;
  @JsonKey(name: 'is_verticale')
  final int? isVerticale;

  HelpResult({
    required this.id,
    this.description,
    this.url,
    this.isVerticale,
  });

  factory HelpResult.fromJson(Map<String, dynamic> json) =>
      _$HelpResultFromJson(json);

  Map<String, dynamic> toJson() => _$HelpResultToJson(this);
}
