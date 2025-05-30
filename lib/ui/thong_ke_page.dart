import 'package:app/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:app/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<ThongKe> fetchThongKe() async {
  final authService = AuthService();

  final token = await authService.getToken();
  final payload = authService.decodeToken(token!);
  final accId = payload!['nameid'].toString();

  final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/ThongKe/${accId}');

  final response = await http.get(
    url,
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
  );

  if (response.statusCode == 200 && json.decode(response.body)['code'] == 200) {
    final jsonData = json.decode(response.body);
    return ThongKe.fromJson(jsonData['data']);
  } else {
    throw Exception('Lỗi khi tải thống kê');
  }
}

class ThongKePage extends StatefulWidget {
  const ThongKePage({super.key});

  @override
  State<ThongKePage> createState() => _ThongKePageState();
}

class _ThongKePageState extends State<ThongKePage> {
  ThongKe? thongKe;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadThongKe();
  }

  Future<void> loadThongKe() async {
    try {
      final data = await fetchThongKe();
      setState(() {
        thongKe = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thống kê cá nhân")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (thongKe == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Thống kê cá nhân"),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_rounded,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  "Không có dữ liệu thống kê",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[1000],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Bạn cần tham gia hiến máu để xem thống kê tại đây.",
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
      appBar: AppBar(title: const Text("Thống kê cá nhân")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCard(
              icon: Icons.bloodtype,
              iconColor: Colors.red,
              title: "Số lần hiến máu",
              value: "${thongKe!.soLanHien} lần",
            ),
            _buildCard(
              icon: Icons.water_drop,
              iconColor: Colors.blue,
              title: "Tổng lượng máu đã hiến",
              value: "${thongKe!.tongLuongMau} ml",
            ),
            _buildCard(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: "Lần hiến gần nhất",
              value: thongKe!.lanCuoiHien != null
                  ? DateFormat('dd/MM/yyyy - HH:mm')
                      .format(DateTime.parse(thongKe!.lanCuoiHien.toString()))
                  : "Chưa có",
            ),
            _buildCard(
              icon: Icons.emoji_events,
              iconColor: Colors.amber[800]!,
              title: "Thành tích",
              value: thongKe!.danhHieu.toString(),
            ),
            _buildCard(
              icon: Icons.card_giftcard,
              iconColor: Colors.purple,
              title: "Số quà đã nhận",
              value: "${thongKe!.soQuaDaNhan} phần quà",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 15)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ThongKe {
  final int soLanHien;
  final int tongLuongMau;
  final DateTime? lanCuoiHien;
  final String danhHieu;
  final int soQuaDaNhan;

  ThongKe({
    required this.soLanHien,
    required this.tongLuongMau,
    required this.lanCuoiHien,
    required this.danhHieu,
    required this.soQuaDaNhan,
  });

  factory ThongKe.fromJson(Map<String, dynamic> json) {
    return ThongKe(
      soLanHien: json['soLanHien'],
      tongLuongMau: json['tongLuongMau'],
      lanCuoiHien: json['lanCuoiHien'] != null
          ? DateTime.parse(json['lanCuoiHien'])
          : null,
      danhHieu: json['danhHieu'] ?? "Chưa có",
      soQuaDaNhan: json['soQuaDaNhan'],
    );
  }
}
