import 'package:dio/dio.dart';
import 'auth_service.dart';
import 'dart:async';

class TokenService {
  final DateTime expiryTime;

  final StreamController<bool> _tokenExpiryController = StreamController<bool>.broadcast();

  TokenService(this.expiryTime) {
    // Timer.periodic(Duration(minutes: 1), (timer) {
    //   if (DateTime.now().isAfter(expiryTime)) {
    //     _tokenExpiryController.add(true);  // Token đã hết hạn
    //   }
    // });
    Duration timeUntilExpiry = expiryTime.difference(DateTime.now());
    if (timeUntilExpiry.isNegative) {
      _tokenExpiryController.add(true);
    } else {
      Timer(timeUntilExpiry, () {
        _tokenExpiryController.add(true);
      });
    }
  }

  Stream<bool> get tokenExpiredStream => _tokenExpiryController.stream;
}

class TokenAutoService {
  final _authService = AuthService();
  final Dio _dio = Dio();

  TokenAutoService() {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        String? token = await _authService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (DioException error, handler) async {
        _authService.logoutUser();
        return handler.next(error);
      },
    ));
  }
}
