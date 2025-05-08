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
  bool daHienMau = false;
  Map<String, dynamic>? TNV;

  @override
  void initState() {
    super.initState();
    fetchDotHM();
    fetchThongTin();
    fetchTNV();
    fetchCoQuan();
    fetchTheTich();
    fetchProvinces();
  }

  String? gioiTinh, tinh, huyen, xa, coQuan, theTich, dotHienMau;
  int? selectedDotHienMau;
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

  List<dynamic> provinces = [];
  List<dynamic> districts = [];
  List<dynamic> wards = [];

  String? selectedProvinceId;
  String? selectedDistrictId;
  String? selectedWardId;

  DateTime? selectedNgaySinh;
  DateTime? selectedTGDangKy;

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

  Future<void> fetchTNV() async {
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
        _isLoading = false;
      });
    } else {
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

  Future<void> fetchThongTin() async {
    setState(() {
      _isLoading = true;
    });
    final authService = AuthService();

    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/TinhNguyenVien/accId/${accId}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final resBody = json.decode(response.body);
      if (resBody['code'] == 200) {
        setState(() {
          daHienMau = true;
          _isLoading = false;
        });
      }
      if (resBody['code'] == 404 || resBody['code'] == 400) {
        final cccd = await getCCCD();
        setState(() {
          cccdController.text = cccd.toString();
          daHienMau = false;
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        daHienMau = false;
        _isLoading = false;
      });
    }
  }

  Future<dynamic> getCCCD() async {
    setState(() {
      _isLoading = true;
    });

    final authService = AuthService();
    final token = await authService.getToken();
    final payload = authService.decodeToken(token!);
    final accId = payload!['nameid'].toString();

    final url = Uri.parse('${ApiConfig.baseUrl}/Account/AccId/$accId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });

    if (response.statusCode == 200) {
      final resBody = json.decode(response.body);
      if (resBody['code'] == 200) {
        return resBody['data'];
      }
    }

    setState(() {
      _isLoading = false;
    });

    return null;
  }

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
      } else if (body['code'] == 400) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(body['message'])));
      } else {
        print(res.body);
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
                          onChanged: (val) => setState(() {
                            dotHienMau = val;
                            final selected = dotHienMauOptions.firstWhere(
                              (e) {
                                final tenDot = e['tenDot'];
                                final diaDiem = e['diaDiem'];
                                final thoiGianBatDau = DateFormat('dd/MM/yyyy')
                                    .format(
                                        DateTime.parse(e['thoiGianBatDau']));
                                final thoiGianKetThuc = DateFormat('dd/MM/yyyy')
                                    .format(
                                        DateTime.parse(e['thoiGianKetThuc']));
                                final display =
                                    '$tenDot - $diaDiem ($thoiGianBatDau - $thoiGianKetThuc)';
                                return display == val;
                              },
                              orElse: () => null,
                            );

                            if (selected != null) {
                              selectedDotHienMau = selected['maDot'];
                            }
                          }),
                        ),
                        if (dotHienMau != null) ...{
                          if (!daHienMau) ...{
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
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: TextFormField(
                                        controller: cccdController,
                                        decoration: InputDecoration(
                                            labelText: 'CCCD',
                                            border: const OutlineInputBorder()),
                                        validator: (value) =>
                                            value == null || value.isEmpty
                                                ? 'Vui lòng nhập cccd'
                                                : null,
                                        enabled: false,
                                      ),
                                    ),
                                    _buildTextField(
                                        label: 'Họ tên',
                                        controller: hoTenController),
                                    _buildNgaySinhPicker(label: 'Ngày sinh'),
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
                            const SizedBox(height: 16)
                          },
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
                                  _buildTGDangKyPicker(
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
      if (daHienMau) {
        final selectedCoQuan =
            coQuanOptions.firstWhere((e) => e['tenDV'] == coQuan);
        final selectedTheTich =
            theTichOptions.firstWhere((e) => e['label'].toString() == theTich);

        final hienMauData = {
          "maDot": selectedDotHienMau,
          "cccd": TNV!['cccd'],
          "maTheTich": selectedTheTich['value'],
          "maDV": selectedCoQuan['maDV'],
          "ngheNghiep": ngheNghiepController.text,
          "noiO": noiOController.text,
          "thoiGianDangKy": selectedTGDangKy!.toIso8601String(),
        };

        final ok = await createTTHienMau(hienMauData);
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Gửi đăng ký thành công')));
          _formKey.currentState!.reset();
          setState(() {
            selectedDotHienMau = null;
            selectedTGDangKy = null;
            coQuan = theTich = null;
            noiOController.clear();
            ngheNghiepController.clear();
          });
        }
      } else {
        final authService = AuthService();

        final token = await authService.getToken();
        final payload = authService.decodeToken(token!);
        final accId = payload!['nameid'].toString();
        final selectedCoQuan =
            coQuanOptions.firstWhere((e) => e['tenDV'] == coQuan);
        final selectedTheTich =
            theTichOptions.firstWhere((e) => e['label'].toString() == theTich);
        final selectedProvince = provinces.firstWhere((e) => e['name'] == tinh);
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
          "taiKhoan_ID": accId
        };
        final cccd = await createTinhNguyenVien(tnData);
        if (cccd != null) {
          final hienMauData = {
            "maDot": selectedDotHienMau,
            "cccd": cccd,
            "maTheTich": selectedTheTich['value'],
            "maDV": selectedCoQuan['maDV'],
            "ngheNghiep": ngheNghiepController.text,
            "noiO": noiOController.text,
            "thoiGianDangKy": selectedTGDangKy!.toIso8601String(),
          };

          final ok = await createTTHienMau(hienMauData);
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Gửi đăng ký thành công')));
            _formKey.currentState!.reset();
            setState(() {
              daHienMau = true;
              selectedDotHienMau = null;
              selectedNgaySinh = null;
              selectedTGDangKy = null;
              gioiTinh = coQuan = theTich = tinh = huyen = xa = null;
              cccdController.clear();
              hoTenController.clear();
              sdtController.clear();
              emailController.clear();
              noiOController.clear();
              ngheNghiepController.clear();
            });
          }
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng điền đầy đủ thông tin')));
    }
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

  Widget _buildNgaySinhPicker({required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedNgaySinh ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime(2101),
          );
          if (picked != null) {
            setState(() {
              selectedNgaySinh = picked;
            });
          }
        },
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

  Widget _buildTGDangKyPicker({required String label}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final dot = dotHienMauOptions
              .firstWhere((e) => e['maDot'] == selectedDotHienMau);

          final firstDate = DateTime.parse(dot['thoiGianBatDau']);
          final lastDate = DateTime.parse(dot['thoiGianKetThuc']);

          final DateTime? picked = await showDatePicker(
            context: context,
            initialDate: selectedTGDangKy ??
                DateTime(firstDate.year, firstDate.month, firstDate.day),
            firstDate: DateTime(firstDate.year, firstDate.month, firstDate.day),
            lastDate: DateTime(lastDate.year, lastDate.month, lastDate.day),
          );
          if (picked != null) {
            setState(() {
              selectedTGDangKy = picked;
            });
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
          child: Text(
            selectedTGDangKy != null
                ? "${selectedTGDangKy!.day}/${selectedTGDangKy!.month}/${selectedTGDangKy!.year}"
                : 'Chọn ngày',
          ),
        ),
      ),
    );
  }
}
