import 'dart:async';
import 'package:http/http.dart';
import 'package:surveyapp/services/auth_service.dart' show pb;

class DatabaseService {
  Future<void> delete(String collection, String id) async {
    await pb.collection(collection).delete(id);
  }

  Future<void> update(String collection, String id, Map<String, dynamic> data,
      {List<MultipartFile>? files}) async {
    await pb.collection(collection).update(id, body: data, files: files ?? []);
  }

  Future<Map<String, dynamic>> create(
      String collection, Map<String, dynamic> data,
      {List<MultipartFile>? files}) async {
    final response = await pb.collection(collection).create(
          body: data,
          files: files ?? [],
        );
    return response.data;
  }

  Future<List<T>> getAll<T>(
    String collection, {
    required T Function(Map<String, dynamic> map) fromMap,
    String? filter,
    String? sort,
    String? expand,
  }) async {
    final response = await pb
        .collection(collection)
        .getFullList(filter: filter, sort: sort, expand: expand);
    final data = response.map((r) => fromMap(r.data)).toList();
    return data;
  }
}
