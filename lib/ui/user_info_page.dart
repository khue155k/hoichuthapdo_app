import 'package:app/api_config.dart';
import 'package:app/service/auth_service.dart';
import 'package:app/ui/dang_ky_HM_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  Map<String, dynamic>? tnv;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchThongTin();
  }

  String tinhThanh = "";
  String quanHuyen = "";
  String phuongXa = "";

  Future<void> fetchThongTin() async {
    final authService = AuthService();

    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/accId/$accId');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final resBody = json.decode(response.body);
      if (resBody['code'] == 200) {
        setState(() {
          tnv = resBody['data'];
          fetchTinh(tnv!['maTinhThanh']);
          fetchHuyen(tnv!['maQuanHuyen']);
          fetchXa(tnv!['maPhuongXa']);
          isLoading = false;
        });
      }
      if (resBody['code'] == 404 || resBody['code'] == 400) {
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTinh(int id) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/Address/province?provinceId=$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        tinhThanh = jsonData['name'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchHuyen(int id) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/Address/district?districtId=$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        quanHuyen = jsonData['name'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchXa(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Address/ward?wardId=$id');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        phuongXa = jsonData['name'];
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tnv == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Bạn chưa hiến máu lần nào\ntrên hệ thống!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Vui lòng đăng ký hiến máu trước.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const DangKyHienMauPage(), // thay bằng màn đăng ký của bạn
                              ),
                            );
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text(
                            'Đăng ký hiến máu ngay',
                            style: TextStyle(fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    elevation: 6,
                    shadowColor: Colors.black26,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildRowWithIcon(Icons.badge, 'CCCD', tnv!['cccd']),
                          _divider(),
                          _buildRowWithIcon(
                              Icons.person, 'Họ tên', tnv!['hoTen']),
                          _divider(),
                          _buildRowWithIcon(Icons.cake, 'Ngày sinh',
                              formatNgay(tnv!['ngaySinh'])),
                          _divider(),
                          _buildRowWithIcon(
                              Icons.wc, 'Giới tính', tnv!['gioiTinh']),
                          _divider(),
                          _buildRowWithIcon(
                              Icons.phone, 'SĐT', tnv!['soDienThoai']),
                          _divider(),
                          _buildRowWithIcon(Icons.email, 'Email',
                              tnv!['email'] ?? 'Không có'),
                          _divider(),
                          _buildRowWithIcon(Icons.location_city, 'Địa chỉ',
                              "$phuongXa, $quanHuyen, $tinhThanh"),
                        ],
                      ),
                    ),
                  ),
                ),
    );
  }

  String formatNgay(String isoDate) {
    final date = DateTime.parse(isoDate);
    return "${date.day}/${date.month}/${date.year}";
  }

  Widget _buildRowWithIcon(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: const TextStyle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return const Divider(color: Colors.grey, height: 1);
  }
}
