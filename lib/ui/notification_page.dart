import 'dart:convert';
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
  List<Notification> _notiList = [];
  int _currentPage = 1;
  final int _pageSize = 10;
  int? _totalItem;
  String _searchTitle = '';
  late ScrollController _sc;

  String? _selectedStatus = 'Chưa đóng';
  int _selectedStatusNum = 1;
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

  void _onSelectedChanged(String? newValue) {
    _selectedStatus = newValue;
    _notiList = [];
    _totalItem = null;
    _fetchNoti();
  }

  Future<void> _fetchNoti() async {
    if (_totalItem != null && _notiList.length == _totalItem) return;
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      _selectedStatus == "Chưa đóng"
          ? _selectedStatusNum = 1
          : _selectedStatusNum = 0;

      final response = await http.get(Uri.parse(
          '${ApiConfig.baseUrl}/Notification/notificationByTitleStatus?title=$_searchTitle&status=$_selectedStatusNum&pageNumber=$_currentPage&pageSize=$_pageSize'));
      if (response.statusCode == 200) {
        final resBody = json.decode(response.body);

        final listItems = resBody['items'] as List;
        _notiList.addAll(
            listItems.map((noti) => Notification.fromJson((noti))).toList());

        _totalItem = resBody['totalNotis'];

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
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(width: 1),
                    ),
                    child: Dropdown(
                      selectedValue: _selectedStatus,
                      onSelectedChanged: _onSelectedChanged,
                    ),
                  ),
                ),
                Expanded(
                  flex: 7,
                  child: TextField(
                    onChanged: (value) {
                      _searchTitle = value;
                      _notiList = [];
                      _totalItem = null;
                      _fetchNoti();

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
              ],
            )),
      ),
      body: _notiList.isEmpty
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
                    itemCount: _notiList.length + 1,
                    separatorBuilder: (BuildContext context, int index) {
                      return const Divider();
                    },
                    itemBuilder: (BuildContext context, int index) {
                      if (index == _notiList.length) {
                        return _buildProgressIndicator();
                      }
                      final item = _notiList[index];
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (item.title != null)
                                  Expanded(
                                    child: Text(item.title!,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.black)),
                                  ),
                                Text(timeAgo(item.update_at),
                                    style:
                                        Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                            if (item.message != null) Text(item.message!),
                            if (item.img_url != null)
                              Container(
                                height: 200,
                                margin: const EdgeInsets.only(top: 8.0),
                                child: FadeInImage.assetNetwork(
                                  placeholder: 'assets/img_placeholder.png',
                                  image: item.img_url!,
                                  imageErrorBuilder:
                                      (context, error, stackTrace) =>
                                          Image.asset(
                                    'assets/img_placeholder.png',
                                  ),
                                ),
                              ),
                          ],
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

class Notification {
  int id;
  int admin_id;
  String? title;
  String? message;
  String? img_url;
  DateTime send_at;
  DateTime update_at;
  int status;

  Notification(
      {required this.id,
      required this.admin_id,
      this.title,
      this.message,
      this.img_url,
      required this.send_at,
      required this.update_at,
      required this.status});

  factory Notification.fromJson(Map<String, dynamic> map) {
    return Notification(
        id: map['id'],
        admin_id: map['admin_id'],
        title: map['title'],
        message: map['message'],
        img_url: map['img_url'],
        send_at: DateTime.parse(map['send_at']),
        update_at: DateTime.parse(map['update_at']),
        status: map['status']);
  }
}
