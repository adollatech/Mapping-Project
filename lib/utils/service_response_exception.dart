import 'package:surveyapp/models/service_response.dart';

class ServiceResponseException {
  ServiceResponse response;
  ServiceResponseException(this.response);
  @override
  String toString() {
    return 'ServiceResponseException: ${response.status} - ${response.message}';
  }

  String get message {
    return response.message ?? 'An unknown error occurred';
  }

  String get status {
    return response.status == ServiceResponseStatus.success
        ? 'Success'
        : 'Error';
  }

  String get error {
    return response.error ?? 'An unknown error occurred';
  }

  String get data {
    return response.data.toString();
  }
}
