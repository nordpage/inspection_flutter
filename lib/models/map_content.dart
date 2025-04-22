class MapContent {
  int? id;
  String? fileName;
  int? status;
  int? documentId;
  String? textInspection;
  int? statusInspection;
  int? sectionId;
  String? hash;

  MapContent({
    this.id,
    this.fileName,
    this.status,
    this.documentId,
    this.textInspection,
    this.statusInspection,
    this.sectionId,
    this.hash,
  });

  factory MapContent.fromJson(Map<String, dynamic> json) {
    return MapContent(
      id: json['id'],
      sectionId: json['section_id'],
      fileName: json['file_name'],
      status: json['status'],
      documentId: json['document_id'],
      textInspection: json['text_inspection'],
      statusInspection: json['status_inspection'],
      hash: json['hash'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'file_name': fileName,
      'status': status,
      'document_id': documentId,
      'text_inspection': textInspection,
      'status_inspection': statusInspection,
      'section_id': sectionId,
      'hash': hash,
    };
  }
}