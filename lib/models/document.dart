// models/document.dart

class Document {
  int? id;
  String? statusText;
  int? status;
  int? mapPhotoId;

  Document({
    this.id,
    this.statusText,
    this.status,
    this.mapPhotoId
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      id: json['id'],
      statusText: json['status_text'],
      status: json['status'],
      mapPhotoId: json['map_photo_id']
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status_text': statusText,
      'status': status,
      'map_photo_id': mapPhotoId
    };
  }
}