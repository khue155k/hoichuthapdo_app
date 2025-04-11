import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api_config.dart';

class AddressService {
  final String apiUrl = ApiConfig.baseUrl;

  Future<List<dynamic>> getProvinces() async {
    final response = await http.get(Uri.parse('$apiUrl/Address/provinces'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không lấy được danh sách tỉnh');
    }
  }

  Future<List<dynamic>> getDistricts(String provinceId) async {
    final response = await http.get(Uri.parse(
        '$apiUrl/Address/districts/provinceId?provinceId=$provinceId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không lấy được danh sách huyện');
    }
  }

  Future<List<dynamic>> getWards(String districtId) async {
    final response = await http.get(
        Uri.parse('$apiUrl/Address/wards/districtId?districtId=$districtId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Không lấy được danh sách xã');
    }
  }
}
