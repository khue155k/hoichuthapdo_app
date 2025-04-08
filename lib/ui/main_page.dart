import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../service/auth_service.dart';
import '../service/token_service.dart';

class MainPage extends StatefulWidget {
  final String companyId;
  final String name;
  final String email;

  const MainPage({
    super.key,
    required this.companyId,
    required this.name,
    required this.email,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  late final String apikeyOneSignal;
  @override
  void initState() {
    _listenTokenExpiry();
    // apikeyOneSignal = dotenv.env['API_KEY_ONESIGNAL']!;
    super.initState();
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);//debug
    OneSignal.initialize('3b4635bd-6b3b-4d8a-85f4-ca3161daba43');
    OneSignal.Notifications.requestPermission(true);
  }

  _listenTokenExpiry() async{
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
    debugPrint(expiryTime.toString());
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
    // const HomePage(),
    // const NotificationPage(),
    // AccountPage(companyId: widget.companyId, name: widget.name, email: widget.email)
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
