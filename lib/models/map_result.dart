import 'package:json_annotation/json_annotation.dart';
import 'documents.dart';
import 'map_section.dart';

part 'map_result.g.dart';

@JsonSerializable(explicitToJson: true)
class MapResult {
  final String? address;
  @JsonKey(name: 'client_fio')
  final String clientFio;
  @JsonKey(name: 'is_upload')
  final int isUpload;
  @JsonKey(name: 'upload_msg')
  final String uploadMsg;
  final List<Documents>? documents;
  @JsonKey(name: 'data')
  final List<MapSection>? sections;

  MapResult({
    this.address,
    required this.clientFio,
    required this.isUpload,
    required this.uploadMsg,
    this.documents,
    this.sections,
  });

  factory MapResult.fromJson(Map<String, dynamic> json) =>
      _$MapResultFromJson(json);

  Map<String, dynamic> toJson() => _$MapResultToJson(this);
}
