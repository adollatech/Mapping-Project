import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:hive_ce/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:surveyapp/models/service_response.dart';
import 'package:surveyapp/utils/service_response_exception.dart';

enum AuthState { unknown, authenticated, unauthenticated }

PocketBase get pb {
  final box = Hive.box("auth");

  final store = AsyncAuthStore(
    save: (String data) async => box.put('pb_auth', data),
    initial: box.get('pb_auth'),
  );
  return PocketBase('http://127.0.0.1:8090', authStore: store);
}

class AuthService extends ChangeNotifier {
  Future<RecordAuth> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await pb.collection("users").authWithPassword(email, password);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  String get userId => pb.authStore.record?.id ?? '';

  Future<RecordModel> register(Map<String, dynamic> user) async {
    try {
      final record = await pb.collection("users").create(body: user);
      await pb.collection("users").requestVerification(user["email"]);
      return record;
    } on ClientException catch (e) {
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<RecordModel> profile(String userId) {
    return pb.collection("users").getOne(userId);
  }

  void signOut() {
    pb.authStore.clear();
    Hive.box("auth").clear();
  }
}
