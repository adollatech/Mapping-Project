import 'dart:async';
import 'dart:developer';

import 'package:flutter/foundation.dart'; // For ChangeNotifier
import 'package:hive_ce/hive.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:surveyapp/models/service_response.dart';
import 'package:surveyapp/utils/service_response_exception.dart';

enum AuthState { unknown, authenticated, unauthenticated }

PocketBase get pb {
  final box = Hive.box("settings");

  final store = AsyncAuthStore(
    save: (String data) async => box.put('pb_auth', data),
    initial: box.get('pb_auth'),
  );
  return PocketBase(
    'https://bluegill-fitting-oddly.ngrok-free.app', 
    authStore: store);
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

  Future<RecordModel> profile() {
    return pb.collection("users").getOne(pb.authStore.record?.id ?? '');
  }

  Future<void> requestVerification(String email) async {
    try {
      await pb.collection("users").requestVerification(email);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<void> verifyEmail(String token) async {
    try {
      await pb.collection("users").confirmVerification(token);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<void> requestPasswordReset(String email) async {
    try {
      await pb.collection("users").requestPasswordReset(email);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<void> resetPassword(
      String token, String password, String passwordConfirm) async {
    try {
      await pb
          .collection("users")
          .confirmPasswordReset(token, password, passwordConfirm);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<RecordAuth> refreshAuth() async {
    try {
      return await pb.collection("users").authRefresh();
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  Future<RecordModel> updateProfile(Map<String, dynamic> details) async {
    try {
      return await pb
          .collection('users')
          .update(pb.authStore.record?.id ?? '', body: details);
    } on ClientException catch (e) {
      log(e.toString(), error: e.response);
      throw ServiceResponseException(ServiceResponse.fromJson(e.response));
    }
  }

  void signOut() {
    pb.authStore.clear();
    Hive.box("settings").clear();
  }
}
