import 'package:app/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LichSuHienMauPage extends StatefulWidget {
  const LichSuHienMauPage({super.key});

  @override
  State<LichSuHienMauPage> createState() => _LichSuHienMauPageState();
}

class _LichSuHienMauPageState extends State<LichSuHienMauPage> {
  bool _isLoading = true;
  List<dynamic> lichSu = [];

  @override
  void initState() {
    super.initState();
    _fetchLichSu();
  }

  Future<void> _fetchLichSu() async {
    final authService = AuthService();

    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url =
        Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/LichSu/${accId}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 && jsonDecode(response.body)['code'] == 200) {
      setState(() {
        lichSu = json.decode(response.body)['data'];
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Lịch sử hiến máu")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (lichSu.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Lịch sử hiến máu"),
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
                  "Chưa có lịch sử hiến máu",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[1000],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Hãy tham gia một đợt hiến máu để có lịch sử tại đây.",
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
      appBar: AppBar(title: const Text("Lịch sử hiến máu")),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: lichSu.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = lichSu[index];
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
                  Text(
                    item['thoiGianHien'] != null
                        ? "🕒 Thời gian hiến: ${formatDateTime(item['thoiGianHien'])}"
                        : "🕒 Thời gian hiến: Không có",
                  ),
                  Text("💧 Thể tích: ${item['theTich']} ml"),
                  Text("📍 Địa điểm: ${item['diaDiem'] ?? 'Không rõ'}"),
                  Builder(
                    builder: (context) {
                      final String ketQua = item['ketQua'] ?? 'Không có';
                      String icon = '';
                      if (ketQua == 'Đã hiến') {
                        icon = ' ✅';
                      } else if (ketQua == 'Chưa hiến' || ketQua == 'Từ chối') {
                        icon = ' ❌';
                      }
                      return Text("📄 Kết quả: $ketQua$icon");
                    },
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
