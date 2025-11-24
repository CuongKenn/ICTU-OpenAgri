import 'package:flutter/material.dart';
import '../screens/dashboard_screen.dart';
import '../screens/satellite_monitoring_screen.dart';
import '../screens/field_map_screen.dart';

class AppNavigationBar extends StatelessWidget implements PreferredSizeWidget {
  final int currentIndex;

  const AppNavigationBar({super.key, required this.currentIndex});

  @override
  Size get preferredSize {
    // Sử dụng BuildContext để xác định size chính xác
    return const Size.fromHeight(kToolbarHeight);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      toolbarHeight: isDesktop ? 70 : 60,
      title: Padding(
        padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 12),
        child: Row(
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF4A5C52)),
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (route) => false);
                  },
                  tooltip: 'Về trang chủ',
                ),
                const SizedBox(width: 4),
                _buildLogo(),
                const SizedBox(width: 8),
                const Text(
                  'AgriSmart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111813),
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            if (isDesktop) ...[
              const SizedBox(width: 32),
              Expanded(child: _buildNavigationTabs(context)),
            ],
            if (!isDesktop) const Spacer(),
            _buildActions(isDesktop),
          ],
        ),
      ),
      bottom: !isDesktop
          ? PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade200, width: 1),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: _buildNavigationTabs(context),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildActions(bool isDesktop) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Color(0xFF111813),
          ),
          onPressed: () {},
        ),
        if (isDesktop)
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF111813)),
            onPressed: () {},
          ),
        const SizedBox(width: 8),
        const CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF0BDA50),
          child: Icon(Icons.person, color: Colors.white, size: 20),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF0BDA50),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.eco, color: Colors.white, size: 14),
    );
  }

  Widget _buildNavigationTabs(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildNavTab(
            context: context,
            label: isDesktop ? 'Dashboard' : 'Bảng điều khiển',
            isActive: currentIndex == 0,
            onTap: () => _navigateTo(context, 0),
          ),
          _buildNavTab(
            context: context,
            label: isDesktop ? 'Bản đồ Vùng trồng' : 'Bản đồ',
            isActive: currentIndex == 1,
            onTap: () => _navigateTo(context, 1),
          ),
          _buildNavTab(
            context: context,
            label: isDesktop ? 'Giám sát Vệ tinh' : 'Vệ tinh',
            isActive: currentIndex == 2,
            onTap: () => _navigateTo(context, 2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTab({
    required BuildContext context,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 12,
          vertical: isDesktop ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF111813) : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: isDesktop ? 14 : 13,
            fontWeight: FontWeight.w500,
            color: isActive ? Colors.white : const Color(0xFF608a6e),
          ),
        ),
      ),
    );
  }

  void _navigateTo(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget destination;
    if (index == 0) {
      destination = const DashboardScreen();
    } else if (index == 1) {
      destination = const FieldMapScreen();
    } else if (index == 2) {
      destination = const SatelliteMonitoringScreen();
    } else {
      return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
