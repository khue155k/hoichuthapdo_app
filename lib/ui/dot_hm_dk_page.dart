import 'package:app/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DotHienMauDangKyPage extends StatefulWidget {
  const DotHienMauDangKyPage({super.key});

  @override
  State<DotHienMauDangKyPage> createState() => _DotHienMauDangKyPageState();
}

class _DotHienMauDangKyPageState extends State<DotHienMauDangKyPage> {
  bool _isLoading = true;
  List<dynamic> dotHM = [];

  @override
  void initState() {
    super.initState();
    _fetchDotHM();
  }

  Future<void> _fetchDotHM() async {
    final authService = AuthService();

    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url =
        Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/DotHmDaDK/${accId}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 && jsonDecode(response.body)['code'] == 200) {
      setState(() {
        dotHM = json.decode(response.body)['data'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String formatDateTime(String dateTimeStr) {
    final dateTime = DateTime.parse(dateTimeStr).toLocal();
    return DateFormat("HH:mm - dd/MM/yyyy").format(dateTime);
  }

  Future<void> _cancelRegistration(String idDotHM) async {
    final authService = AuthService();
    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/HuyDangKyHM/$accId?maDot=$idDotHM');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 && jsonDecode(response.body)['code'] == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Huỷ đăng ký thành công")),
      );
      _fetchDotHM();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Huỷ đăng ký thất bại")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Đợt hiến máu đã đăng ký")),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (dotHM.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Đợt hiến máu đã đăng ký"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  "Chưa có đợt hiến máu",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[1000],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Hãy đăng ký một đợt hiến máu.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[800],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Đợt hiến máu đã đăng ký")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: dotHM.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = dotHM[index];
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item['tenDot'] ?? 'Đợt hiến máu',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("🕒 Thời gian đăng ký: ${formatDateTime(item['thoiGianDangKy'])}"),
                  Text("📍 Địa điểm: ${item['diaDiem'] ?? 'Không rõ'}"),
                  Text("💧 Thể tích: ${item['theTich']} ml"),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red.withOpacity(0.1),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text("Xác nhận huỷ đăng ký"),
                            content: const Text("Bạn có chắc muốn huỷ đăng ký đợt hiến máu này không?"),
                            actions: [
                              TextButton(
                                child: const Text("Không"),
                                onPressed: () => Navigator.pop(context, false),
                              ),
                              TextButton(
                                child: const Text("Huỷ đăng ký"),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          await _cancelRegistration(item['maDot'].toString());
                        }
                      },
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      label: const Text("Huỷ đăng ký", style: TextStyle(color: Colors.red)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
