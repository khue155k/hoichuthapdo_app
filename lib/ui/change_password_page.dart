import 'dart:convert';

import 'package:flutter/material.dart';
import '../api_config.dart';
import '../service/auth_service.dart';
import '../ui/login_page.dart';
import 'package:http/http.dart' as http;

class ChangePassword extends StatelessWidget {
  final String username;
  const ChangePassword({super.key, required this.username});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Đổi mật khẩu"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: _FormContent(username: username),
          ),
        ),
      ),
    );
  }
}

class _FormContent extends StatefulWidget {
  final String username;
  const _FormContent({required this.username});

  @override
  State<_FormContent> createState() => _FormContentState();
}

class _FormContentState extends State<_FormContent> {
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final _authService = AuthService();

  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
  }

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: TextEditingController(text: widget.username),
              style: const TextStyle(color: Colors.black),
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Tài khoản',
                prefixIcon: Icon(Icons.person_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            _gap(),
            TextFormField(
              controller: _oldPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nhập mật khẩu cũ';
                }
                return null;
              },
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                  labelText: 'Mật khẩu cũ',
                  hintText: 'Nhập mật khẩu cũ',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )),
            ),
            _gap(),
            TextFormField(
              controller: _newPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nhập mật khẩu mới';
                }
                if (value.length < 6) {
                  return 'Mật khẩu phải có ít nhất 6 kí tự';
                }
                if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
                  return 'Mật khẩu phải chứa ít nhất một ký tự không phải chữ cái';
                }
                if (!RegExp(r'[A-Z]').hasMatch(value)) {
                  return 'Mật khẩu phải có ít nhất một chữ hoa';
                }
                if (!RegExp(r'[a-z]').hasMatch(value)) {
                  return 'Mật khẩu phải có ít nhất một chữ thường';
                }
                return null;
              },
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                  labelText: 'Mật khẩu mới',
                  hintText: 'Nhập mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )),
            ),
            _gap(),
            TextFormField(
              controller: _confirmPasswordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nhập lại mật khẩu mới';
                }
                if (_confirmPasswordController.text !=
                    _newPasswordController.text) {
                  return 'Mật khẩu mới và xác nhận mật khẩu mới phải giống nhau';
                }
                return null;
              },
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu mới',
                  hintText: 'Nhập lại mật khẩu mới',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_isPasswordVisible
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )),
            ),
            _gap(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Text(
                    'Đổi mật khẩu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                onPressed: () async {
                  try {
                    if (_formKey.currentState!.validate()) {
                      String oldPassword = _oldPasswordController.text;
                      String newPassword = _newPasswordController.text;

                      final authService = AuthService();
                      final token = await authService.getToken();

                      final response = await http.post(
                          Uri.parse(
                              '${ApiConfig.baseUrl}/Account/ChangePassword'),
                          headers: {
                            'Authorization': 'Bearer $token',
                            'Content-Type': 'application/json',
                          },
                          body: jsonEncode({
                            'username': widget.username,
                            'oldPassword': oldPassword,
                            'newPassword': newPassword
                          }));
                      final body = jsonDecode(response.body);
                      if (response.statusCode == 200 && body['code'] == 200) {
                        _authService.deleteToken();

                        showDialog(
                          // ignore: use_build_context_synchronously
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Thông báo'),
                              content: const Text(
                                  "Đổi mật khẩu thành công. Vui lòng đăng nhập lại"),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                            const LoginPage()));
                                  },
                                  child: const Text('OK'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                      else if (body['code'] == 400) {
                        _showAlertDialog(body['message']);
                      } else {
                        _showAlertDialog('Có lỗi sảy ra. Vui lòng thử lại sau');
                      }
                    }
                  } catch (e) {
                    setState(() {
                      _showAlertDialog(
                          "Không thể kết nối đến máy chủ: Error $e");
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);

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
}
