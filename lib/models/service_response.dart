enum ServiceResponseStatus {
  success,
  error,
}

class ServiceResponse {
  final Map<String, dynamic>? data;
  final ServiceResponseStatus status;
  final String? message;
  final String? error;

  ServiceResponse({this.data, required this.status, this.message, this.error});

  factory ServiceResponse.fromJson(Map<String, dynamic> json) {
    return ServiceResponse(
      data: json['data'] as Map<String, dynamic>?,
      status: json['status'] == 200
          ? ServiceResponseStatus.success
          : ServiceResponseStatus.error,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }
}
