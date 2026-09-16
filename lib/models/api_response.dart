class MutationResult {
  final bool success;
  final String message;
  final dynamic data;
  final Map<String, dynamic>? errors;
  final Map<String, dynamic>? rawRoot;

  MutationResult({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.rawRoot,
  });

  factory MutationResult.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      final status = json['status'];
      final verdict = json['success'];
      final isSuccess = verdict is bool
          ? verdict
          : (status == 'success' || status == true);
      final message = json['message']?.toString() ??
          (isSuccess ? 'Operasi berhasil' : 'Operasi gagal');
      final errors = json['errors'] is Map<String, dynamic>
          ? json['errors'] as Map<String, dynamic>
          : null;

      return MutationResult(
        success: isSuccess,
        message: message,
        data: json['data'],
        errors: errors,
        rawRoot: json,
      );
    }
    return MutationResult(
      success: false,
      message: 'Respons server tidak valid',
    );
  }

  void ensureSuccess() {
    if (!success) {
      throw Exception(message);
    }
  }

  dynamic operator [](String key) {
    switch (key) {
      case 'success':
        return success;
      case 'message':
        return message;
      case 'data':
        return data;
      case 'errors':
        return errors;
      default:
        if (rawRoot != null && rawRoot!.containsKey(key)) {
          return rawRoot![key];
        }
        return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data,
        if (errors != null) 'errors': errors,
        ...?rawRoot,
      };
}
