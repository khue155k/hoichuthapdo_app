import 'package:flutter/material.dart';
import '../service/address_service.dart';
import '../service/auth_service.dart';
import '../api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DangKyHienMauPage extends StatefulWidget {
  const DangKyHienMauPage({super.key});

  @override
  State<DangKyHienMauPage> createState() => _DangKyHienMauPageState();
}

class _DangKyHienMauPageState extends State<DangKyHienMauPage> {
  final _formKey = GlobalKey<FormState>();
  final addressService = AddressService();
  final authService = AuthService();

  @override
  void initState() {
    super.initState();
    fetchProvinces();
    fetchCoQuan();
    fetchTheTich();
  }

  String? gioiTinh, coQuan, theTich, tinh, huyen, xa;
  final cccdController = TextEditingController();
  final hoTenController = TextEditingController();
  final sdtController = TextEditingController();
  final emailController = TextEditingController();
  final noiOController = TextEditingController();
  final ngheNghiepController = TextEditingController();

  final List<String> gioiTinhOptions = ['Nam', 'Nữ'];
  List<dynamic> coQuanOptions = [];
  List<dynamic> theTichOptions = [];

  Future<List<dynamic>> getCoQuan() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/DonVi'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Không lấy được danh sách cơ quan');
    }
  }

  Future<void> fetchCoQuan() async {
    coQuanOptions = await getCoQuan();
    debugPrint(coQuanOptions.toString());
    setState(() {});
  }

  Future<List<dynamic>> getTheTich() async {
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/DotHienMau/TheTichMH'));
    if (response.statusCode == 200) {
      debugPrint(jsonDecode(response.body).toString());
      return jsonDecode(response.body)['data'];
    } else {
      throw Exception('Không lấy được danh sách thê tích máu hiến');
    }
  }

  Future<void> fetchTheTich() async {
    theTichOptions = await getTheTich();
    setState(() {});
  }

  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  String? selectedProvinceId;
  String? selectedDistrictId;
  String? selectedWardId;

  Future<void> fetchProvinces() async {
    provinces = await addressService.getProvinces();
    setState(() {});
  }

  Future<void> fetchDistricts(String provinceId) async {
    districts = await addressService.getDistricts(provinceId);
    wards = [];
    selectedDistrictId = null;
    selectedWardId = null;
    setState(() {});
  }

  Future<void> fetchWards(String districtId) async {
    wards = await addressService.getWards(districtId);
    selectedWardId = null;
    setState(() {});
  }

  DateTime? selectedNgaySinh;
  DateTime? selectedTGDangKy;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedNgaySinh ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        selectedNgaySinh = picked;
      });
    }
  }

  Future<String?> createTinhNguyenVien(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/createTNV');
    try {
      final token = await authService.getToken();

      final res = await http.post(url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token"
          },
          body: jsonEncode(data));

      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['code'] == 200) {
        return body['data']['id'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Có lỗi khi tạo tình nguyện viên')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
    return null;
  }

  Future<bool> createTTHienMau(Map<String, dynamic> data) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/TTHienMau/createTTHienMau');
    try {
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(data));
      final body = jsonDecode(res.body);
      if (res.statusCode == 200 && body['code'] == 200) {
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Có lỗi khi đăng ký hiến máu')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi kết nối: $e')));
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký hiến máu')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            _buildTextField(label: 'CCCD', controller: cccdController),
            _buildTextField(label: 'Họ tên', controller: hoTenController),
            _buildDatePicker(),
            _buildDropdown(
                label: 'Giới tính',
                value: gioiTinh,
                items: gioiTinhOptions,
                onChanged: (val) => setState(() => gioiTinh = val)),
            _buildTextField(label: 'Số điện thoại', controller: sdtController),
            _buildTextFieldNoR(label: 'Email', controller: emailController),
            _buildTextField(
                label: 'Nơi ở hiện tại', controller: noiOController),
            _buildTextField(
                label: 'Nghề nghiệp hiện tại',
                controller: ngheNghiepController),
            _buildDropdown(
                label: 'Cơ quan',
                value: coQuan,
                items: coQuanOptions
                    .map<String>((e) => e['tenDV'].toString())
                    .toList(),
                onChanged: (val) => setState(() => coQuan = val)),
            const SizedBox(height: 8),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text("Địa chỉ thường trú",
                    style: TextStyle(fontWeight: FontWeight.bold))),
            const SizedBox(height: 8),
            _buildDropdown(
              label: 'Tỉnh/Thành',
              value: tinh,
              items:
                  provinces.map<String>((e) => e['name'].toString()).toList(),
              onChanged: (val) {
                setState(() {
                  tinh = val;
                  huyen = null;
                  xa = null;

                  final selectedProvince =
                      provinces.firstWhere((e) => e['name'] == val);
                  selectedProvinceId =
                      selectedProvince['provinceId'].toString();
                  fetchDistricts(selectedProvinceId!);
                });
              },
            ),
            _buildDropdown(
              label: 'Quận/Huyện',
              value: huyen,
              items:
                  districts.map<String>((e) => e['name'].toString()).toList(),
              onChanged: (val) {
                setState(() {
                  huyen = val;
                  xa = null;

                  final selectedDistrict =
                      districts.firstWhere((e) => e['name'] == val);
                  selectedDistrictId =
                      selectedDistrict['districtId'].toString();
                  fetchWards(selectedDistrictId!);
                });
              },
            ),
            _buildDropdown(
              label: 'Phường/Xã',
              value: xa,
              items: wards.map<String>((e) => e['name'].toString()).toList(),
              onChanged: (val) => setState(() {
                xa = val;

                final selectedWard = wards.firstWhere((e) => e['name'] == val);
                selectedWardId = selectedWard['wardId'].toString();
              }),
            ),
            _buildDateTimePicker(label: 'Thời gian đăng ký'),
            _buildDropdown(
                label: 'Thể tích',
                value: theTich,
                items: theTichOptions
                    .map<String>((e) => e['label'].toString())
                    .toList(),
                onChanged: (val) => setState(() => theTich = val)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final selectedCoQuan =
                      coQuanOptions.firstWhere((e) => e['tenDV'] == coQuan);
                  final selectedTheTich = theTichOptions
                      .firstWhere((e) => e['label'].toString() == theTich);
                  final selectedProvince =
                      provinces.firstWhere((e) => e['name'] == tinh);
                  final selectedDistrict =
                      districts.firstWhere((e) => e['name'] == huyen);
                  final selectedWard = wards.firstWhere((e) => e['name'] == xa);

                  final tnData = {
                    "hoTen": hoTenController.text,
                    "ngaySinh": "${selectedNgaySinh!.toIso8601String()}",
                    "cccd": cccdController.text,
                    "gioiTinh": gioiTinh,
                    "soDienThoai": sdtController.text,
                    "email": emailController.text,
                    "maTinhThanh": selectedProvince['provinceId'],
                    "maQuanHuyen": selectedDistrict['districtId'],
                    "maPhuongXa": selectedWard['wardId'],
                    "soLanHien": 0
                  };
                  final cccd = await createTinhNguyenVien(tnData);
                  if (cccd != null) {
                    final hienMauData = {
                      "id": 0,
                      "maDot": 1,
                      "CCCD": cccd,
                      "maTheTich": selectedTheTich['value'],
                      "maDV": selectedCoQuan['maDV'],
                      "ngheNghiep": ngheNghiepController.text,
                      "noiO": noiOController.text,
                      "thoiGianDangKy": selectedTGDangKy!.toIso8601String(),
                      "ketQua": "Chưa hiến"
                    };

                    final ok = await createTTHienMau(hienMauData);
                    if (ok) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Gửi đăng ký thành công')));
                      _formKey.currentState!.reset();
                      setState(() {
                        selectedNgaySinh = null;
                        selectedTGDangKy = null;
                        gioiTinh = coQuan = theTich = tinh = huyen = xa = null;
                      });
                    }
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Vui lòng điền đầy đủ thông tin')));
                }
              },
              child: const Text('Gửi đăng ký'),
            )
          ]),
        ),
      ),
    );
  }

  Widget _buildTextField(
      {required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        validator: (value) =>
            value == null || value.isEmpty ? 'Vui lòng nhập $label' : null,
      ),
    );
  }

  Widget _buildTextFieldNoR(
      {required String label, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
            labelText: label, border: const OutlineInputBorder()),
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Vui lòng chọn $label' : null,
      ),
    );
  }

  Widget _buildDatePicker({String label = 'Ngày sinh'}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _selectDate,
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          child: Text(
            selectedNgaySinh != null
                ? "${selectedNgaySinh!.day}/${selectedNgaySinh!.month}/${selectedNgaySinh!.year}"
                : 'Chọn ngày',
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimePicker({required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final pickedDate = await showDatePicker(
            context: context,
            initialDate: selectedTGDangKy ?? DateTime.now(),
            firstDate: DateTime.now().subtract(const Duration(days: 1)),
            lastDate: DateTime(2101),
          );
          if (pickedDate != null) {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(DateTime.now()),
            );
            if (pickedTime != null) {
              setState(() {
                selectedTGDangKy = DateTime(
                  pickedDate.year,
                  pickedDate.month,
                  pickedDate.day,
                  pickedTime.hour,
                  pickedTime.minute,
                );
              });
            }
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          child: Text(
            selectedTGDangKy != null
                ? "${selectedTGDangKy!.day}/${selectedTGDangKy!.month}/${selectedTGDangKy!.year} - ${selectedTGDangKy!.hour.toString().padLeft(2, '0')}:${selectedTGDangKy!.minute.toString().padLeft(2, '0')}"
                : 'Chọn ngày và giờ',
          ),
        ),
      ),
    );
  }
}
