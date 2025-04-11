import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMenuCard(
              context,
              icon: Icons.favorite,
              title: 'Đăng ký hiến máu',
              onTap: () {
                // Điều hướng tới màn hình đăng ký hiến máu
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              icon: Icons.bar_chart,
              title: 'Xem thống kê',
              onTap: () {
                // Điều hướng tới màn hình thống kê
              },
            ),
            const SizedBox(height: 16),
            _buildMenuCard(
              context,
              icon: Icons.history,
              title: 'Xem lịch sử',
              onTap: () {
                // Điều hướng tới màn hình lịch sử
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
        required String title,
        required VoidCallback onTap}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
