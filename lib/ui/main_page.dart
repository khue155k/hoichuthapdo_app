import 'package:app/api_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../ui/home_page.dart';
import '../ui/notification_page.dart';
import '../ui/account_page.dart';

import '../service/auth_service.dart';
import '../service/token_service.dart';

class MainPage extends StatefulWidget {
  final String username;

  const MainPage({
    super.key,
    required this.username,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  @override
  void initState() {
    super.initState();

    _listenTokenExpiry();
    initOneSignal();
  }

  _listenTokenExpiry() async {
    AuthService authService = AuthService();
    DateTime expiryTime = DateTime.now();
    String? token = await authService.getToken();
    if (token != null) {
      Map<String, dynamic> payload = authService.decodeToken(token) ?? {};
      final exp = payload['exp'];
      if (exp is int) {
        expiryTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
    }

    TokenService tokenService = TokenService(expiryTime);
    tokenService.tokenExpiredStream.listen((expired) {
      if (expired) {
        authService.logoutUser();
        _showAlertDialog("Phiên đăng nhập hết hạn vui lòng đăng nhập lại");
      }
    });
  }

  void _showAlertDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Thông báo'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  late final List<Widget> _bodyContent = [
    const HomePage(),
    const NotificationPage(),
    AccountPage(username: widget.username)
  ];

  void _changeIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _bodyContent.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _changeIndex,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_active),
            label: "Thông báo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_box_rounded),
            label: "Tài khoản",
          ),
        ],
      ),
    );
  }
}

Future<void> initOneSignal() async {
  final appIdOneSignal = dotenv.env['APP_ID_ONESIGNAL']!;
  // OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize(appIdOneSignal);

  OneSignal.Notifications.requestPermission(true).then((granted) {
    // print("🔔 Permission granted: $granted");
  });

  OneSignal.User.pushSubscription.addObserver((state) {
    if (state.current?.id != null) {
      updatePlayerIdToServer(state.current!.id!);
    }
  });

  Future.delayed(const Duration(seconds: 5), () {
    final id = OneSignal.User.pushSubscription.id;
    updatePlayerIdToServer(id!);
  });
}

Future<void> updatePlayerIdToServer(String onesignalID) async {
  final authService = AuthService();

  final token = await authService.getToken();
  final payload = authService.decodeToken(token!);
  final TaiKhoan_ID = payload!['nameid'].toString();

  final response = await http.put(
    Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/updateOnesignalID'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json'
    },
    body: jsonEncode({
      'TaiKhoan_ID': TaiKhoan_ID,
      'OneSiginal_ID': onesignalID,
    }),
  );

  // if (response.statusCode == 200) {
  //   print('onesignalID đã cập nhật lên server');
  // } else {
  //   print('Lỗi khi cập nhật onesignalID');
  // }
}
