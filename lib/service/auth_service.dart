import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

import '../api_config.dart';
import '../main.dart';

class AuthService {
  final apiUri = Uri.parse("${ApiConfig.baseUrl}/Login");
  final storage = const FlutterSecureStorage();

  Future<bool> isLoggedIn() async {
    String? token = await getToken();

    if (token != null) {
      Map<String, dynamic> payload = decodeToken(token) ?? {};
      return !isTokenExpired(payload);
    }

    return false;
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      final response = await http.post(apiUri,
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode({'email': email, 'password': password}));

      if (response.statusCode == 200) {
        var resBody = jsonDecode(response.body);
        String token = resBody['token'];
        await saveToken(token);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveToken(String token) async {
    Map<String, dynamic> payload = decodeToken(token) ?? {};
    await storage.write(key: 'saved_email', value: payload['email']);
    return storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() {
    return storage.read(key: 'auth_token');
  }

  Future<void> deleteToken() {
    return storage.delete(key: 'auth_token');
  }

  void logoutUser() async {
    await deleteToken();
    navigatorKey.currentState?.pushReplacementNamed('/login');
  }

  bool isTokenExpired(Map<String, dynamic> payload) {
    final exp = payload['exp'];
    if (exp is int) {
      final expiryDate = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      final currentDate = DateTime.now();

      return currentDate.isAfter(expiryDate);
    } else {
      return false;
    }
  }

  Map<String, dynamic>? decodeToken(String token) {
    final jwt = JWT.decode(token);
    return jwt.payload;
  }
}
