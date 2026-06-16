class LoginResponse {
  final String token;
  final String refreshToken;
  final int expiresIn;
  final String nim;

  LoginResponse({
    required this.token,
    required this.refreshToken,
    required this.expiresIn,
    required this.nim,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] ?? '',
        refreshToken: json['refreshToken'] ?? '',
        expiresIn: json['expiresIn'] ?? 0,
        nim: json['nim'] ?? '',
      );
}
