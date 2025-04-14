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
    final accId = int.tryParse(payload!['nameid'].toString());

    final url =
        Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/LichSu/${accId}');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        lichSu = json.decode(response.body);
        print(lichSu);
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
    return DateFormat("dd/MM/yyyy - HH:mm").format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (lichSu.isEmpty) {
      return const Scaffold(
        body: Center(child: Text("Chưa có lịch sử hiến máu.")),
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
                  Text("✅ Kết quả: ${item['ketQua'] ?? 'Không có'}"),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
