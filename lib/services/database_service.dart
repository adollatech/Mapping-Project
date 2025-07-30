import 'dart:async';

import 'package:surveyapp/services/auth_service.dart' show pb;

class DatabaseService {
  Future<void> delete(String collection, String id) async {
    await pb.collection(collection).delete(id);
  }
}
