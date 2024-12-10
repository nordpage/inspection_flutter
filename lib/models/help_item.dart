// models/help_item.dart

class HelpItem {
  int? id;
  String? description;
  String? url;
  int? isVerticale;

  HelpItem({
    this.id,
    this.description,
    this.url,
    this.isVerticale,
  });

  factory HelpItem.fromJson(Map<String, dynamic> json) {
    return HelpItem(
      id: json['id'],
      description: json['description'],
      url: json['url'],
      isVerticale: json['is_verticale'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'url': url,
      'is_verticale': isVerticale,
    };
  }
}