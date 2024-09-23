import 'package:json_annotation/json_annotation.dart';

part 'documents.g.dart';

@JsonSerializable()
class Documents {
  final int id;
  final int status;
  @JsonKey(name: 'status_text')
  final String statusText;

  Documents({
    required this.id,
    required this.status,
    required this.statusText,
  });

  factory Documents.fromJson(Map<String, dynamic> json) =>
      _$DocumentsFromJson(json);
  Map<String, dynamic> toJson() => _$DocumentsToJson(this);
}
