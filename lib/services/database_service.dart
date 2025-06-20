import 'dart:async';

import 'package:surveyapp/services/auth_service.dart' show pb;

class DatabaseService {
  Future<void> deleteContact(String id) async {
    await delete('contacts', id);
  }

  Future<void> delete(String collection, String id) async {
    await pb.collection(collection).delete(id);
  }
}
