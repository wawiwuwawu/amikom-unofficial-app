class LoginResponse {
  final String token;
  final String refreshToken;
  final String nim;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.nim,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        nim: json['nim'] ?? '',
      );
}
