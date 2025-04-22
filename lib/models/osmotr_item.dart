class OsmotrItem {
  final int id;
  final String osmotrField1; // Дата осмотра
  final String osmotrField2; // Время осмотра
  final String jkName;       // Название ЖК
  String jkColor;            // Цвет ЖК (с возможностью get/set)
  final String clientFio;    // ФИО клиента
  final String clientPhone;  // Телефон клиента
  final int komnat;          // Количество комнат
  final int stoimost;        // Стоимость оценки
  final String primechaniya; // Примечание к приемке
  final int referPriemka;    // Флаг: приемка квартиры (0 или 1)
  final int referOcenka;     // Флаг: оценка квартиры (0 или 1)
  final int lidOcenka;       // Флаг: передача лида (0 или 1)
  final int stoimostPriemki; // Стоимость приемки
  final String ecspertNaOsmotreTxt; // Примечание к оценке
  final String otchetDlya;   // Банк для оценки
  final int moneyExpert;     // Флаг: деньги получены (0 или 1)

  OsmotrItem({
    required this.id,
    required this.osmotrField1,
    required this.osmotrField2,
    required this.jkName,
    this.jkColor = "#000000",
    required this.clientFio,
    required this.clientPhone,
    required this.komnat,
    required this.stoimost,
    required this.primechaniya,
    required this.referPriemka,
    required this.referOcenka,
    required this.lidOcenka,
    required this.stoimostPriemki,
    required this.ecspertNaOsmotreTxt,
    required this.otchetDlya,
    required this.moneyExpert,
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
      komnat: json['komnat'] is int
          ? json['komnat']
          : int.tryParse(json['komnat']?.toString() ?? '0') ?? 0,
      stoimost: json['stoimost'] is int
          ? json['stoimost']
          : int.tryParse(json['stoimost']?.toString() ?? '0') ?? 0,
      primechaniya: json['primechaniya'] ?? '',
      referPriemka: json['refer_priemka'] is int
          ? json['refer_priemka']
          : int.tryParse(json['refer_priemka']?.toString() ?? '0') ?? 0,
      referOcenka: json['refer_ocenka'] is int
          ? json['refer_ocenka']
          : int.tryParse(json['refer_ocenka']?.toString() ?? '0') ?? 0,
      lidOcenka: json['lid_ocenka'] is int
          ? json['lid_ocenka']
          : int.tryParse(json['lid_ocenka']?.toString() ?? '0') ?? 0,
      stoimostPriemki: json['stoimost_priemki'] is int
          ? json['stoimost_priemki']
          : int.tryParse(json['stoimost_priemki']?.toString() ?? '0') ?? 0,
      ecspertNaOsmotreTxt: json['ecspert_na_osmotre_txt'] ?? '',
      otchetDlya: json['otchet_dlya'] ?? '',
      moneyExpert: json['money_expert'] is int
          ? json['money_expert']
          : int.tryParse(json['money_expert']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "osmotr_field_1": osmotrField1,
      "osmotr_field_2": osmotrField2,
      "jk_name": jkName,
      "jk_color": jkColor,
      "client_fio": clientFio,
      "client_phone": clientPhone,
      "komnat": komnat,
      "stoimost": stoimost,
      "primechaniya": primechaniya,
      "refer_priemka": referPriemka,
      "refer_ocenka": referOcenka,
      "lid_ocenka": lidOcenka,
      "stoimost_priemki": stoimostPriemki,
      "ecspert_na_osmotre_txt": ecspertNaOsmotreTxt,
      "otchet_dlya": otchetDlya,
      "money_expert": moneyExpert,
    };
  }
}