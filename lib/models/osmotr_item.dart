class OsmotrItem {
  final int id;
  final String osmotrField1; // Дата осмотра
  final String osmotrField2; // Время осмотра
  final String jkName;       // Название ЖК
  final String jkColor;      // Цвет для календаря
  final String clientFio;    // ФИО клиента
  final String clientPhone;  // Телефон клиента
  final String komnat;       // Количество комнат
  final String stoimost;     // Стоимость
  final String ecspertNaOsmotre;

  OsmotrItem({
    required this.id,
    required this.osmotrField1,
    required this.osmotrField2,
    required this.jkName,
    required this.jkColor,
    required this.clientFio,
    required this.clientPhone,
    required this.komnat,
    required this.stoimost,
    required this.ecspertNaOsmotre
  });

  factory OsmotrItem.fromJson(Map<String, dynamic> json) {
    return OsmotrItem(
      id: json['id'] ?? 0,
      osmotrField1: json['osmotr_field_1'] ?? '',
      osmotrField2: json['osmotr_field_2'] ?? '',
      jkName: json['jk_name'] ?? '',
      jkColor: json['jk_color'] ?? '#000000',
      clientFio: json['client_fio'] ?? '',
      clientPhone: json['client_phone'] ?? '',
      komnat: json['komnat'] ?? '',
      stoimost: json['stoimost'] ?? '',
      ecspertNaOsmotre: json['ecspert_na_osmotre'] ?? ''
    );
  }
}