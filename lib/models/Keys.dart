class Keys {
  String _status;
  String _accesskey;
  String _secretkey;

  Keys({
    required String status,
    required String accesskey,
    required String secretkey,
  })  : _status = status,
        _accesskey = accesskey,
        _secretkey = secretkey;

  Keys.fromJson(dynamic json)
      : _status = json['status'] as String,
        _accesskey = json['ACCESS_KEY'] as String,
        _secretkey = json['SECRET_KEY'] as String;

  Keys copyWith({
    String? status,
    String? accesskey,
    String? secretkey,
  }) =>
      Keys(
        status: status ?? _status,
        accesskey: accesskey ?? _accesskey,
        secretkey: secretkey ?? _secretkey,
      );

  String get status => _status;
  set status(String value) => _status = value;

  String get accesskey => _accesskey;
  set accesskey(String value) => _accesskey = value;

  String get secretkey => _secretkey;
  set secretkey(String value) => _secretkey = value;

  Map<String, dynamic> toJson() {
    return {
      'status': _status,
      'ACCESS_KEY': _accesskey,
      'SECRET_KEY': _secretkey,
    };
  }
}