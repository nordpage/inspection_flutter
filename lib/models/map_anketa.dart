class MapAnketa {
  final int? id;
  final int? komnat;
  final int? sanUzel;
  final int? balkon;
  final int? storonSOknami;
  final int? dopPomesheniy;
  final int? isFirstEtazh;
  final int? isMusoroprovod;
  final int? isLift;

  MapAnketa({
    this.id,
    this.komnat,
    this.sanUzel,
    this.balkon,
    this.storonSOknami,
    this.dopPomesheniy,
    this.isFirstEtazh,
    this.isMusoroprovod,
    this.isLift,
  });

  factory MapAnketa.fromJson(Map<String, dynamic> json) {
    return MapAnketa(
      id: json['id'],
      komnat: json['komnat'],
      sanUzel: json['san_uzel'],
      balkon: json['balkon'],
      storonSOknami: json['storon_s_oknami'],
      dopPomesheniy: json['dop_pomesheniy'],
      isFirstEtazh: json['is_first_etazh'],
      isMusoroprovod: json['is_musoroprovod'],
      isLift: json['is_lift'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'komnat': komnat,
      'san_uzel': sanUzel,
      'balkon': balkon,
      'storon_s_oknami': storonSOknami,
      'dop_pomesheniy': dopPomesheniy,
      'is_first_etazh': isFirstEtazh,
      'is_musoroprovod': isMusoroprovod,
      'is_lift': isLift,
    };
  }
}