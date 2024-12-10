// models/map_section.dart

import 'map_content.dart';
import 'help_item.dart';

class MapSection {
  int? id;
  int? n;
  String? name;
  String? description;
  String? url;
  int? minPhoto;
  List<HelpItem>? helpList;
  List<MapContent>? contentList;

  MapSection({
    this.id,
    this.n,
    this.name,
    this.description,
    this.url,
    this.minPhoto,
    this.helpList,
    this.contentList,
  });

  factory MapSection.fromJson(Map<String, dynamic> json) {
    return MapSection(
      id: json['id'],
      n: json['n'],
      name: json['name'],
      description: json['description'],
      url: json['url'],
      minPhoto: json['min_photo'],
      helpList: json['help_list'] != null
          ? List<HelpItem>.from(json['help_list'].map((x) => HelpItem.fromJson(x)))
          : [],
      contentList: [], // Инициализируем пустым списком, т.к. контент может быть добавлен позже
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'n': n,
      'name': name,
      'description': description,
      'url': url,
      'min_photo': minPhoto,
      'help_list': helpList?.map((x) => x.toJson()).toList(),
      // contentList не отправляем на сервер
    };
  }
}