import 'document.dart';
import 'map_section.dart';

class MapResult {
  String? address;
  String? clientFio;
  int? isUpload;
  String? uploadMsg;
  List<Document>? documents;
  List<MapSection>? sections;
  String? orderNumber;

  MapResult({
    this.address,
    this.clientFio,
    this.isUpload,
    this.uploadMsg,
    this.documents,
    this.sections,
    this.orderNumber,
  });

  factory MapResult.fromJson(Map<String, dynamic> json) {
    return MapResult(
      address: json['address'],
      clientFio: json['client_fio'],
      isUpload: json['is_upload'],
      uploadMsg: json['upload_msg'],
      documents: json['documents'] != null
          ? List<Document>.from(json['documents'].map((x) => Document.fromJson(x)))
          : [],
      sections: json['data'] != null
          ? List<MapSection>.from(json['data'].map((x) => MapSection.fromJson(x)))
          : [],
      orderNumber: json['order_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'client_fio': clientFio,
      'is_upload': isUpload,
      'upload_msg': uploadMsg,
      'documents': documents?.map((x) => x.toJson()).toList(),
      'data': sections?.map((x) => x.toJson()).toList(),
      'order_number': orderNumber,
    };
  }
}