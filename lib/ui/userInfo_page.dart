import 'package:app/api_config.dart';
import 'package:app/service/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserInfoPagePage extends StatefulWidget {
  const UserInfoPagePage({super.key});

  @override
  State<UserInfoPagePage> createState() => _UserInfoPagePageState();
}

class _UserInfoPagePageState extends State<UserInfoPagePage> {
  Map<String, dynamic>? TNV;
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

    final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/accId/${accId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        TNV = jsonData['data'];
        fetchTinh(TNV!['maTinhThanh']);
        fetchHuyen(TNV!['maQuanHuyen']);
        fetchXa(TNV!['maPhuongXa']);
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchTinh(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/Address/province?provinceId=${id}');
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
    final url = Uri.parse('${ApiConfig.baseUrl}/Address/district?districtId=${id}');
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
    final url = Uri.parse('${ApiConfig.baseUrl}/Address/ward?wardId=${id}');
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
        title: const Text('Thông tin tình nguyện viên'),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TNV == null
              ? const Center(child: Text('Không lấy được dữ liệu'))
              : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Thông Tin Tình Nguyện Viên',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                _buildRowWithIcon(Icons.badge, 'CCCD', TNV!['cccd']),
                _divider(),
                _buildRowWithIcon(Icons.person, 'Họ tên', TNV!['hoTen']),
                _divider(),
                _buildRowWithIcon(Icons.cake, 'Ngày sinh', formatNgay(TNV!['ngaySinh'])),
                _divider(),
                _buildRowWithIcon(Icons.wc, 'Giới tính', TNV!['gioiTinh']),
                _divider(),
                _buildRowWithIcon(Icons.phone, 'SĐT', TNV!['soDienThoai']),
                _divider(),
                _buildRowWithIcon(Icons.email, 'Email', TNV!['email'] ?? 'Không có'),
                _divider(),
                _buildRowWithIcon(Icons.location_city, 'Địa chỉ', "$phuongXa, $quanHuyen, $tinhThanh"),
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
