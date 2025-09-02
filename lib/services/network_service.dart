import 'package:pocketbase/pocketbase.dart';
import 'package:surveyapp/models/service_response.dart';
import 'package:surveyapp/utils/service_response_exception.dart';

class NetworkService {
  PocketBase pb;
  NetworkService(this.pb);
  Future<dynamic> create(String collection, dynamic map,
      {String path = "v1"}) async {
    try {
      final result = await pb.send("$path/$collection",
          method: "POST",
          headers: {"Authorization": "Bearer ${pb.authStore.token}"},
          body: (map.runtimeType == List<Map<String, dynamic>>)
              ? {"data": map}
              : map);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> update(
      String collection, int id, Map<String, dynamic> map) async {
    try {
      final result = await pb.send("update/$collection/$id",
          method: "PUT",
          headers: {"Authorization": 'Bearer ${pb.authStore.token}'},
          body: map);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> send(String path, Map<String, dynamic> map,
      {String method = 'POST'}) async {
    try {
      final result = await pb.send(
        path,
        method: method,
        body: map,
        headers: {"Authorization": 'Bearer ${pb.authStore.token}'},
      );
      return result;
    } on ClientException catch (e) {
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }
}
