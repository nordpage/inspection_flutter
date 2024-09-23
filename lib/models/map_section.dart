import 'package:inspection/models/map_content.dart';
import 'package:json_annotation/json_annotation.dart';
import 'help_result.dart';

part 'map_section.g.dart';

@JsonSerializable()
class MapSection {
  final int id;
  final int n;
  final String name;
  final String description;
  final String? url;
  @JsonKey(name: 'min_photo')
  final int? minPhoto;
  @JsonKey(name: 'help_list')
  final List<HelpResult>? helpList;
  @JsonKey(name: 'content_list')
  final List<MapContent>? contentList;
  late final String? userName;

  MapSection({
    required this.id,
    required this.n,
    required this.name,
    required this.description,
    this.url,
    this.minPhoto,
    this.helpList,
    this.contentList,
    this.userName,
  });

  factory MapSection.fromJson(Map<String, dynamic> json) =>
      _$MapSectionFromJson(json);

  Map<String, dynamic> toJson() => _$MapSectionToJson(this);
}
