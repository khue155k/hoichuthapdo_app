import 'dart:convert';
import 'package:app/service/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:async';

import '../api_config.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  bool _isLoading = false;
  List<ThongBao> _thongBaoList = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  int? _totalItem;
  String _searchString = '';
  late ScrollController _sc;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _sc = ScrollController();

    _fetchNoti();
    _sc.addListener(() {
      if (_sc.position.pixels == _sc.position.maxScrollExtent) {
        _fetchNoti();
      }
    });
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  Future<void> _fetchNoti() async {
    final authService = AuthService();
    if (_totalItem != null && _thongBaoList.length == _totalItem) return;

    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      final token = await authService.getToken();
      final response = await http.get(
        Uri.parse(
            '${ApiConfig.baseUrl}/ThongBao/search?string_tim_kiem=$_searchString&pageSize=$_pageSize&currentPage=$_currentPage'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final resBody = json.decode(response.body);

        final listItems = resBody['data']['items'] as List;
        _thongBaoList.addAll(
            listItems.map((TB) => ThongBao.fromJson((TB))).toList());

        _totalItem = resBody['data']['totalCount'];

        _currentPage++;
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  String timeAgo(DateTime dateTime) {
    final Duration diff = DateTime.now().difference(dateTime);

    if (diff.inDays > 0) {
      return diff.inDays == 1 ? 'Hôm qua' : '${diff.inDays} ngày trước';
    } else if (diff.inHours > 0) {
      return diff.inHours == 1 ? '1 giờ trước' : '${diff.inHours} giờ trước';
    } else if (diff.inMinutes > 0) {
      return diff.inMinutes == 1
          ? '1 phút trước'
          : '${diff.inMinutes} phút trước';
    } else if (diff.inSeconds > 0) {
      return diff.inSeconds == 1 ? 'Vừa xong' : '${diff.inSeconds} giây trước';
    } else {
      return 'Vừa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: TextField(
            onChanged: (value) {
              _searchString = value;
              _thongBaoList = [];
              _totalItem = null;
              _currentPage = 1;

              if (_debounce?.isActive ?? false) _debounce!.cancel();

              _debounce = Timer(const Duration(milliseconds: 300), () {
                _fetchNoti();
              });
            },
            decoration: const InputDecoration(
              hintText: 'Tìm kiếm...',
              hintStyle: TextStyle(color: Colors.grey),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search, color: Colors.grey),
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
      ),
      body: _thongBaoList.isEmpty
          ? const Center(
              child: Text('Không tìm thấy thông báo.',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)))
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: ListView.separated(
                    controller: _sc,
                    itemCount: _thongBaoList.length + 1,
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                    itemBuilder: (BuildContext context, int index) {
                      if (index == _thongBaoList.length) {
                        return _buildProgressIndicator();
                      }
                      final item = _thongBaoList[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center, // Căn giữa theo chiều dọc
                                children: [
                                  Icon(
                                    Icons.notifications,
                                    color: Colors.redAccent,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (item.tieuDe != null)
                                          Text(
                                            item.tieuDe!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        const SizedBox(height: 4),
                                        Text(
                                          timeAgo(item.thoiGianGui),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),
                              if (item.noiDung != null)
                                Text(
                                  item.noiDung!,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
    );
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
}

class Dropdown extends StatefulWidget {
  final String? selectedValue;
  final ValueChanged<String?> onSelectedChanged;

  Dropdown({
    required this.selectedValue,
    required this.onSelectedChanged,
  });

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: widget.selectedValue,
      icon: const SizedBox.shrink(),
      isExpanded: true,
      iconSize: 24,
      elevation: 16,
      style: const TextStyle(color: Colors.black),
      underline: const SizedBox.shrink(),
      onChanged: (String? newValue) {
        widget.onSelectedChanged(newValue);
      },
      items: _status.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  final List<String> _status = [
    "Chưa đóng",
    "Đã đóng",
  ];
}

class ThongBao {
  int maTB;
  String? tieuDe;
  String? noiDung;
  DateTime thoiGianGui;

  ThongBao({
    required this.maTB,
    this.tieuDe,
    this.noiDung,
    required this.thoiGianGui,
  });

  factory ThongBao.fromJson(Map<String, dynamic> json) {
    return ThongBao(
      maTB: json['maTB'],
      tieuDe: json['tieuDe'],
      noiDung: json['noiDung'],
      thoiGianGui: DateTime.parse(json['thoiGianGui']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maTB': maTB,
      'tieuDe': tieuDe,
      'noiDung': noiDung,
      'thoiGianGui': thoiGianGui.toIso8601String(),
    };
  }
}
