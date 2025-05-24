import 'package:app/ui/chatbot_page.dart';
import 'package:app/ui/dot_hm_dk_page.dart';
import 'package:app/ui/lich_su_HM_page.dart';
import 'package:app/ui/thong_ke_page.dart';
import 'package:flutter/material.dart';
import '../ui/dang_ky_HM_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        centerTitle: true,
      ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.favorite,
                  title: 'Đăng ký hiến máu',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DangKyHienMauPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.fact_check,
                  title: 'Đợt hiến máu đã đăng ký',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DotHienMauDangKyPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.bar_chart,
                  title: 'Xem thống kê',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ThongKePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.history,
                  title: 'Xem lịch sử',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LichSuHienMauPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildMenuCard(
                  context,
                  icon: Icons.smart_toy,
                  title: 'Chat bot AI',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChatbotPage(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        )
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        leading: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
