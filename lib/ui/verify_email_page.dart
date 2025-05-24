import 'package:app/ui/login_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:app/api_config.dart';

class VerifyEmailPage extends StatefulWidget {
  final String username;

  const VerifyEmailPage({super.key, required this.username});

  @override
  State<VerifyEmailPage> createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  final TextEditingController _verificationCodeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Hàm gửi mã xác thực đến backend
  Future<void> _verifyEmail() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/Account/VerifyEmail'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'userName': widget.username,
            'verificationCode': _verificationCodeController.text,
          }),
        );

        if (response.statusCode == 200 && json.decode(response.body)['code'] == 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Thông báo'),
                content: const Text('Xác nhận email thành công!'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginPage()),
                            (Route<dynamic> route) => false,
                      );
                    },
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        } else {
          // Nếu có lỗi
          _showAlertDialog('Mã xác nhận không đúng hoặc hết hạn.');
        }
      } catch (e) {
        _showAlertDialog('Không thể kết nối đến máy chủ: $e');
      }
    }
  }

  // Hiển thị thông báo lỗi
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xác nhận email'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _verificationCodeController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mã xác nhận';
                  }
                  return null;
                },
                decoration: const InputDecoration(
                  labelText: 'Mã xác nhận',
                  hintText: 'Nhập mã xác nhận',
                  prefixIcon: Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _verifyEmail,
                  child: const Padding(
                    padding: EdgeInsets.all(10.0),
                    child: Text(
                      'Xác nhận',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
