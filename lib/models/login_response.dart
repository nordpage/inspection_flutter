class LoginResponse {
  final String status;
  final String role;
  final bool hideAnketa;

  LoginResponse({
    required this.status,
    required this.role,
    required this.hideAnketa,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      status: json['status'],
      role: json['role'],
      hideAnketa: json['hide_anketa'],
    );
  }
}
