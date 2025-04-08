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

// class ApiService {
//
//   final Dio _dio = Dio();
//
//   ApiService() {
//     _dio.interceptors.add(InterceptorsWrapper(
//       onRequest: (options, handler) async {
//         String? token = await _authService.getToken();
//         if (token != null) {
//           options.headers['Authorization'] = 'Bearer $token';
//         }
//         return handler.next(options);
//       },
//       onResponse: (response, handler) {
//         return handler.next(response);
//       },
//       onError: (DioException error, handler) async {
//         try {
//           String? newToken = await refreshToken();
//           if (newToken != null) {
//             final options = Options(
//               method: error.requestOptions.method,
//               headers: {
//                 'Authorization': 'Bearer $newToken',
//                 ...error.requestOptions.headers,
//               },
//               contentType: error.requestOptions.contentType,
//             );
//
//             final retryResponse =
//                 await _dio.request(error.requestOptions.path, options: options);
//
//             return handler.resolve(retryResponse);
//           } else {
//             _authService.logoutUser();
//           }
//         } catch (e) {
//           _authService.logoutUser();
//         }
//
//         return handler.next(error);
//       },
//     ));
//   }
//
//   Future<String?> refreshToken() async {
//     try {
//       final response = await _dio.post(
//         'https://your-api.com/refresh-token',
//         data: {'refresh_token': 'yourRefreshToken'},
//       );
//       if (response.statusCode == 200) {
//         String newToken = response.data['access_token'];
//         await _authService.saveToken(newToken);
//         return newToken;
//       } else {
//         throw Exception('Failed to refresh token');
//       }
//     } catch (e) {
//       throw Exception('Error refreshing token: $e');
//     }
//   }
//
//   Future<Response> getData() async {
//     try {
//       final response = await _dio.get('https://your-api.com/data');
//       return response;
//     } catch (e) {
//       throw Exception('Failed to fetch data: $e');
//     }
//   }
// }
