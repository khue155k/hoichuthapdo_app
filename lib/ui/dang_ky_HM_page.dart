import 'package:flutter/material.dart';
import '../service/address_service.dart';
import '../service/auth_service.dart';
import '../api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class DangKyHienMauPage extends StatefulWidget {
  const DangKyHienMauPage({super.key});

  @override
  State<DangKyHienMauPage> createState() => _DangKyHienMauPageState();
}

class _DangKyHienMauPageState extends State<DangKyHienMauPage> {
  final _formKey = GlobalKey<FormState>();
  final addressService = AddressService();
  final authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDotHM();
    fetchProvinces();
    fetchCoQuan();
    fetchTheTich();
  }

  String? gioiTinh, coQuan, theTich, tinh, huyen, xa, dotHienMau;
  final cccdController = TextEditingController();
  final hoTenController = TextEditingController();
  final sdtController = TextEditingController();
  final emailController = TextEditingController();
  final noiOController = TextEditingController();
  final ngheNghiepController = TextEditingController();

  final List<String> gioiTinhOptions = ['Nam', 'Nữ'];
  List<dynamic> coQuanOptions = [];
  List<dynamic> theTichOptions = [];
  List<dynamic> dotHienMauOptions = [];

  Future<List<dynamic>> getDotHM() async {
    final authService = AuthService();
    final token = await authService.getToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/DotHienMau'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> allDots = jsonDecode(response.body)['data'];

      final now = DateTime.now();

      final List<dynamic> validDots = allDots.where((dot) {
        final thoiGianKetThuc = DateTime.parse(dot['thoiGianKetThuc']);
        return thoiGianKetThuc.isAfter(now);
      }).toList();

      return validDots;
    } else {
      throw Exception('Không lấy được danh sách đợt hiến máu');
    }
  }

  Future<void> fetchDotHM() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      dotHienMauOptions = await getDotHM();
      setState(() {
        _isLoading = false;
      });
    }
  }

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
    setState(() {});
  }

  Future<List<dynamic>> getTheTich() async {
    final response =
        await http.get(Uri.parse('${ApiConfig.baseUrl}/DotHienMau/TheTichMH'));
    if (response.statusCode == 200) {
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
      final res = await http.post(url,
          headers: {"Content-Type": "application/json"},
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : dotHienMauOptions.isEmpty
              ? const Center(
                  child: Text('Hiện tại không có đợt hiến máu nào để đăng ký.',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDropdownLong(
                          label: 'Chọn đợt hiến máu',
                          value: dotHienMau,
                          items: dotHienMauOptions.map<String>((e) {
                            final tenDot = e['tenDot'];
                            final diaDiem = e['diaDiem'];
                            final thoiGianBatDau = DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(e['thoiGianBatDau']));
                            final thoiGianKetThuc = DateFormat('dd/MM/yyyy')
                                .format(DateTime.parse(e['thoiGianKetThuc']));
                            return '$tenDot - $diaDiem ($thoiGianBatDau - $thoiGianKetThuc)';
                          }).toList(),
                          onChanged: (val) => setState(() => dotHienMau = val),
                        ),
                        if (dotHienMau != null) ...{
                          const Text("Thông tin cá nhân",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildTextField(
                                      label: 'CCCD',
                                      controller: cccdController),
                                  _buildTextField(
                                      label: 'Họ tên',
                                      controller: hoTenController),
                                  _buildDatePicker(),
                                  _buildDropdown(
                                      label: 'Giới tính',
                                      value: gioiTinh,
                                      items: gioiTinhOptions,
                                      onChanged: (val) =>
                                          setState(() => gioiTinh = val)),
                                  _buildTextField(
                                      label: 'Số điện thoại',
                                      controller: sdtController),
                                  _buildTextFieldNoR(
                                      label: 'Email',
                                      controller: emailController),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Địa chỉ thường trú",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildDropdown(
                                      label: 'Tỉnh/Thành',
                                      value: tinh,
                                      items: provinces
                                          .map<String>(
                                              (e) => e['name'].toString())
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          tinh = val;
                                          huyen = xa = null;
                                          selectedProvinceId = provinces
                                              .firstWhere((e) =>
                                                  e['name'] ==
                                                  val)['provinceId']
                                              .toString();
                                          fetchDistricts(selectedProvinceId!);
                                        });
                                      }),
                                  _buildDropdown(
                                      label: 'Quận/Huyện',
                                      value: huyen,
                                      items: districts
                                          .map<String>(
                                              (e) => e['name'].toString())
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          huyen = val;
                                          xa = null;
                                          selectedDistrictId = districts
                                              .firstWhere((e) =>
                                                  e['name'] ==
                                                  val)['districtId']
                                              .toString();
                                          fetchWards(selectedDistrictId!);
                                        });
                                      }),
                                  _buildDropdown(
                                      label: 'Phường/Xã',
                                      value: xa,
                                      items: wards
                                          .map<String>(
                                              (e) => e['name'].toString())
                                          .toList(),
                                      onChanged: (val) {
                                        setState(() {
                                          xa = val;
                                          selectedWardId = wards
                                              .firstWhere((e) =>
                                                  e['name'] == val)['wardId']
                                              .toString();
                                        });
                                      }),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text("Thông tin đăng ký hiến máu",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Card(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            elevation: 3,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  _buildTextField(
                                      label: 'Nơi ở hiện tại',
                                      controller: noiOController),
                                  _buildTextField(
                                      label: 'Nghề nghiệp hiện tại',
                                      controller: ngheNghiepController),
                                  _buildDropdown(
                                      label: 'Cơ quan',
                                      value: coQuan,
                                      items: coQuanOptions
                                          .map<String>(
                                              (e) => e['tenDV'].toString())
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => coQuan = val)),
                                  _buildDateTimePicker(
                                      label: 'Thời gian đăng ký'),
                                  _buildDropdown(
                                      label: 'Thể tích',
                                      value: theTich,
                                      items: theTichOptions
                                          .map<String>(
                                              (e) => e['label'].toString())
                                          .toList(),
                                      onChanged: (val) =>
                                          setState(() => theTich = val)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _dangKy,
                            icon: const Icon(Icons.check_circle),
                            label: const Text('Gửi đăng ký'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              textStyle: const TextStyle(fontSize: 16),
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                            ),
                          )
                        }
                      ],
                    ),
                  ),
                ),
    );
  }

  _dangKy() async {
    if (_formKey.currentState!.validate()) {
      final selectedCoQuan =
          coQuanOptions.firstWhere((e) => e['tenDV'] == coQuan);
      final selectedTheTich =
          theTichOptions.firstWhere((e) => e['label'].toString() == theTich);
      final selectedProvince = provinces.firstWhere((e) => e['name'] == tinh);
      final selectedDistrict = districts.firstWhere((e) => e['name'] == huyen);
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
          "maDot": dotHienMau,
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
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gửi đăng ký thành công')));
          _formKey.currentState!.reset();
          setState(() {
            selectedNgaySinh = null;
            selectedTGDangKy = null;
            gioiTinh = coQuan = theTich = tinh = huyen = xa = null;
          });
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
    }
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Center(
        child: Opacity(
          opacity: _isLoading ? 1.0 : 00,
          child: const CircularProgressIndicator(),
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

  Widget _buildDropdownLong({
    required String label,
    required String? value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        value: value,
        isExpanded: true,
        items: items.map((e) {
          return DropdownMenuItem<String>(
            value: e,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 300),
              child: Text(
                e,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
          );
        }).toList(),
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
