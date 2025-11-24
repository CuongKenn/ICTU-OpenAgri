import 'package:flutter/material.dart';
import 'satellite_monitoring_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isDesktop = width > 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: _AgriTechAppBar(isDesktop: isDesktop),
      ),
      drawer: !isDesktop ? const _MobileDrawer() : null,
      body: const SingleChildScrollView(
        child: Column(
          children: [
            _HeroSection(),
            _FeaturesSection(),
            _DataVisualizationSection(),
            _CTASection(),
          ],
        ),
      ),
    );
  }
}

// --- App Bar ---
class _AgriTechAppBar extends StatelessWidget {
  final bool isDesktop;

  const _AgriTechAppBar({required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8F6).withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: CustomPaint(painter: _LogoPainter()),
              ),
              const SizedBox(width: 16),
              const Text(
                'AgriTech',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  letterSpacing: -0.015,
                ),
              ),
              // SizedBox(height: 10,),
              Image.asset("assets/image/OpenAgri.png"),
              if (isDesktop) const SizedBox(width: 40),
              if (isDesktop)
                const Row(
                  children: [
                    _NavLink(title: 'Trang Chủ', onTap: () {}),
                    _NavLink(title: 'Tính Năng', onTap: () {}),
                    _NavLink(
                      title: 'Giám sát Vệ tinh',
                      icon: Icons.satellite_alt,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SatelliteMonitoringScreen(),
                          ),
                        );
                      },
                    ),
                    _NavLink(title: 'Bảng Giá', onTap: () {}),
                    _NavLink(title: 'Liên Hệ', onTap: () {}),
                  ],
                ),
            ],
          ),
          if (isDesktop)
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text(
                    'Đăng Nhập',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DashboardScreen(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0BDA50),
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.dashboard, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Truy Cập Dashboard',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.015,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          if (!isDesktop)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Color(0xFF111827)),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
        ],
      ),
    );
  }
}

// class _LogoPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = const Color(0xFF0BDA50)
//       ..style = PaintingStyle.fill;
//
//     final path = Path();
//     final w = size.width;
//     final h = size.height;
//
//     path.moveTo(w * 0.88, h * 0.92);
//     path.cubicTo(w * 0.88, h * 0.92, w * 0.75, h * 0.71, w * 0.86, h * 0.5);
//     path.cubicTo(w * 0.98, h * 0.27, w * 0.88, h * 0.08, w * 0.88, h * 0.08);
//     path.lineTo(w * 0.15, h * 0.08);
//     path.cubicTo(w * 0.15, h * 0.08, w * 0.24, h * 0.27, w * 0.12, h * 0.5);
//     path.cubicTo(w * 0.02, h * 0.71, w * 0.15, h * 0.92, w * 0.15, h * 0.92);
//     path.close();
//
//     canvas.drawPath(path, paint);
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

class _NavLink extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final IconData? icon;

  const _NavLink({required this.title, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF1F2937),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

class _MobileDrawer extends StatelessWidget {
  const _MobileDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xFF0BDA50)),
            child: Text(
              'AgriTech',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ListTile(title: const Text('Trang Chủ'), onTap: () {}),
          ListTile(title: const Text('Tính Năng'), onTap: () {}),
          ListTile(title: const Text('Bảng Giá'), onTap: () {}),
          ListTile(title: const Text('Liên Hệ'), onTap: () {}),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.satellite_alt, color: Color(0xFF0BDA50)),
            title: const Text('Giám sát Vệ tinh'),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SatelliteMonitoringScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.map, color: Color(0xFF0BDA50)),
            title: const Text('Bản đồ Vùng trồng'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tính năng đang phát triển')),
              );
            },
          ),
          const Divider(),
              title: const Text('Đăng Nhập'),
              onTap: () => Navigator.pushNamed(context, '/login')),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DashboardScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Truy Cập Dashboard'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0BDA50),
                foregroundColor: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Hero Section ---
class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > 1024;
    final isMedium = width > 768;
    final isSmall = width > 480;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Container(
            padding: isSmall ? const EdgeInsets.all(16) : EdgeInsets.zero,
            child: Container(
              constraints: const BoxConstraints(minHeight: 480),
              decoration: BoxDecoration(
                borderRadius:
                    isSmall ? BorderRadius.circular(12) : BorderRadius.zero,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuDRqqZpQIhFgC3S9-LVPhAQzUP0urF1gNv31Wa9avYv08ichaxJoGgqFlFZ4vuvWwyV_xnEyCgAOHYGKzvuQQgFdboP7_TTaEXGU4JIjwZgOhxnZOp1eyimuJgn_Z8fE_wCXG7Rx7kGPLFfLRTzVeBznCDYqZq9582c-1d6RIu_Db8sGMftbQVZB8R9lE3AQijGfObOTWo1AKJiJI9o-mYiwHLPMj9VkgAFccPV9YRCSSd-hqh5VI38cNtMY69XKmXuV9CaPs35ELc',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      isSmall ? BorderRadius.circular(12) : BorderRadius.zero,
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x33000000), Color(0x99000000)],
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 40 : 16,
                  vertical: 40,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nền Tảng Quản Lý Nông Trại Thông Minh',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmall ? 48 : 36,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                        letterSpacing: -0.033,
                      ),
                    ),
                    SizedBox(height: isSmall ? 16 : 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 672),
                      child: Text(
                        'Tối ưu hóa năng suất, giảm thiểu rủi ro và ra quyết định dựa trên dữ liệu. Tất cả công cụ bạn cần trong một dashboard duy nhất.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmall ? 16 : 14,
                          fontWeight: FontWeight.normal,
                          height: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmall ? 32 : 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DashboardScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0BDA50),
                            foregroundColor: const Color(0xFF111827),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 20 : 16,
                              vertical: isSmall ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.dashboard, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Truy Cập Dashboard',
                                style: TextStyle(
                                  fontSize: isSmall ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SatelliteMonitoringScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFFF5F8F6,
                            ).withValues(alpha: 0.9),
                            backgroundColor:
                                const Color(0xFFF5F8F6).withValues(alpha: 0.9),
                            foregroundColor: const Color(0xFF1F2937),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmall ? 20 : 16,
                              vertical: isSmall ? 16 : 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.satellite_alt, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Giám sát Vệ tinh',
                                style: TextStyle(
                                  fontSize: isSmall ? 16 : 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.015,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Features Section ---
class _FeaturesSection extends StatelessWidget {
  const _FeaturesSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > 1024;
    final isMedium = width > 768;
    final isSmall = width > 480;

    return Padding(
      padding: EdgeInsets.only(
        left: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
        right: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
        top: 80,
        bottom: 40,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  children: [
                    Text(
                      'Lợi Ích Chính Cho Người Nông Dân Hiện Đại',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: isSmall ? 36 : 32,
                        fontWeight: isSmall ? FontWeight.w900 : FontWeight.bold,
                        color: const Color(0xFF111827),
                        height: 1.1,
                        letterSpacing: isSmall ? -0.033 : 0,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nền tảng của chúng tôi được trang bị các công cụ tiên tiến nhất để cung cấp cho bạn những thông tin chi tiết hữu ích và đơn giản hóa việc quản lý trang trại.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF374151),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _FeatureGrid(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureData(
        icon: Icons.satellite_alt,
        title: 'Giám sát Vệ tinh',
        description:
            'Theo dõi sức khỏe (Sentinel-2) và độ ẩm đất (Sentinel-1) từ xa.',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tính năng đang phát triển')),
          );
        },
      ),
      _FeatureData(
        icon: Icons.map_outlined,
        title: 'Bản đồ Vùng trồng',
        description:
            'Quản lý diện tích, vị trí và thông tin chi tiết từng vùng trồng.',
        onTap: () {},
      ),
      _FeatureData(
        icon: Icons.bug_report,
        title: 'Cảnh báo Sâu bệnh',
        description:
            'Nhận cảnh báo kịp thời để ngăn ngừa dịch hại và thiệt hại cây trồng.',
      ),
      _FeatureData(
        icon: Icons.science,
        title: 'Phân tích Đất',
        description:
            'Hiểu rõ sức khỏe của đất để tối ưu hóa việc sử dụng phân bón.',
      ),
      _FeatureData(
        icon: Icons.edit_calendar,
        title: 'Lập kế hoạch Mùa vụ',
        description:
            'Công cụ thông minh lên lịch gieo trồng và thu hoạch để đạt năng suất tối đa.',
      ),
      _FeatureData(
        icon: Icons.api,
        title: 'API Dữ liệu Mở',
        description:
            'Dễ dàng tích hợp và chia sẻ dữ liệu nông nghiệp trên các công cụ của bạn.',
      ),
      _FeatureData(
        icon: Icons.attach_money,
        title: 'Giá Nông Sản',
        description:
            'Theo dõi giá cả thị trường nông sản theo thời gian thực và xu hướng giá.',
        route: '/commodity-prices',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= 800) {
          columns = 3;
        } else if (width >= 600) {
          columns = 2;
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.3,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) {
            final feature = features[index];
            return _FeatureCard(
              icon: feature.icon,
              title: feature.title,
              description: feature.description,
              onTap: feature.onTap,
              route: feature.route,
            );
          },
        );
      },
    );
  }
}

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? route;

  _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.route,
  });
}

class _FeatureCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback? onTap;
  final String? route;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    this.onTap,
    this.route,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _isHovered && widget.onTap != null
                  ? const Color(0xFF0BDA50)
                  : const Color(0xFF0BDA50).withValues(alpha: 0.2),
              width: _isHovered && widget.onTap != null ? 2 : 1,
            ),
            boxShadow: _isHovered && widget.onTap != null
                ? [
                    BoxShadow(
                      color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(widget.icon, color: const Color(0xFF0BDA50), size: 28),
                  if (widget.onTap != null)
                    Icon(
                      Icons.arrow_forward,
                      color: _isHovered
                          ? const Color(0xFF0BDA50)
                          : const Color(0xFF0BDA50).withValues(alpha: 0.5),
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
    return InkWell(
      onTap: route != null ? () => Navigator.pushNamed(context, route!) : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF0BDA50),
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                description,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Data Visualization Section ---
class _DataVisualizationSection extends StatelessWidget {
  const _DataVisualizationSection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > 1024;
    final isMedium = width > 768;
    final isSmall = width > 480;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.only(
                  top: 64,
                  bottom: 12,
                  left: 16,
                  right: 16,
                ),
                padding:
                    EdgeInsets.only(top: 64, bottom: 12, left: 16, right: 16),
                child: Text(
                  'Trực Quan Hóa Dữ Liệu Nông Trại Của Bạn',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1.2,
                    letterSpacing: -0.015,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    return Flex(
                      direction: isWide ? Axis.horizontal : Axis.vertical,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isWide)
                          const Expanded(child: _SoilMoistureCard())
                        else
                          const _SoilMoistureCard(),
                        SizedBox(
                          width: isWide ? 16 : 0,
                          height: isWide ? 0 : 16,
                        ),
                        if (isWide)
                          const Expanded(child: _CropHealthCard())
                        else
                          const _CropHealthCard(),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoilMoistureCard extends StatelessWidget {
  const _SoilMoistureCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 288),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Độ Ẩm Đất Thời Gian Thực',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            '68%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                '7 ngày qua',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '+2.5%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                  height: 1.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _BarColumn(
                          label: 'T2',
                          heightPercent: 40,
                          isActive: false,
                        ),
                        _BarColumn(
                          label: 'T3',
                          heightPercent: 50,
                          isActive: false,
                        ),
                        _BarColumn(
                          label: 'T4',
                          heightPercent: 90,
                          isActive: true,
                        ),
                        _BarColumn(
                          label: 'T5',
                          heightPercent: 60,
                          isActive: false,
                        ),
                        _BarColumn(
                          label: 'T6',
                          heightPercent: 70,
                          isActive: false,
                        ),
                        _BarColumn(
                          label: 'T7',
                          heightPercent: 65,
                          isActive: false,
                        ),
                        _BarColumn(
                          label: 'CN',
                          heightPercent: 68,
                          isActive: false,
                        ),
                            label: 'T2', heightPercent: 40, isActive: false),
                        _BarColumn(
                            label: 'T3', heightPercent: 50, isActive: false),
                        _BarColumn(
                            label: 'T4', heightPercent: 90, isActive: true),
                        _BarColumn(
                            label: 'T5', heightPercent: 60, isActive: false),
                        _BarColumn(
                            label: 'T6', heightPercent: 70, isActive: false),
                        _BarColumn(
                            label: 'T7', heightPercent: 65, isActive: false),
                        _BarColumn(
                            label: 'CN', heightPercent: 68, isActive: false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarColumn extends StatelessWidget {
  final String label;
  final double heightPercent;
  final bool isActive;

  const _BarColumn({
    required this.label,
    required this.heightPercent,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: heightPercent / 100,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF0BDA50)
                          : const Color(0xFF0BDA50).withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4B5563),
                letterSpacing: 0.015,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropHealthCard extends StatelessWidget {
  const _CropHealthCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 288),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tình Trạng Sức Khỏe Cây Trồng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '92%',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Row(
          const Row(
            children: [
              Text(
                '30 ngày qua',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF4B5563),
                  height: 1.5,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '+1.8%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF059669),
                  height: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: Column(
              children: [
                Expanded(
                  child: CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _LineChartPainter(),
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      'Tuần 1',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.015,
                      ),
                    ),
                    Text(
                      'Tuần 2',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.015,
                      ),
                    ),
                    Text(
                      'Tuần 3',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.015,
                      ),
                    ),
                    Text(
                      'Tuần 4',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4B5563),
                        letterSpacing: 0.015,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final dataPoints = [
      0.73,
      0.14,
      0.27,
      0.62,
      0.22,
      0.68,
      0.41,
      0.81,
      0.30,
      1.0,
      0.01,
      0.54,
      0.86,
      0.17,
    ];

    final path = Path();
    final step = w / (dataPoints.length - 1);

    path.moveTo(0, h * dataPoints[0]);

    for (int i = 0; i < dataPoints.length - 1; i++) {
      final x1 = i * step;
      final y1 = h * dataPoints[i];
      final x2 = (i + 1) * step;
      final y2 = h * dataPoints[i + 1];

      final cpx = (x1 + x2) / 2;
      path.quadraticBezierTo(cpx, y1, x2, y2);
    }

    final fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0BDA50).withValues(alpha: 0.3),
        const Color(0xFF0BDA50).withValues(alpha: 0.0),
      ],
    );

    final fillPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = const Color(0xFF0BDA50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// --- CTA Section ---
class _CTASection extends StatelessWidget {
  const _CTASection();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isLarge = width > 1024;
    final isMedium = width > 768;
    final isSmall = width > 480;

    return Padding(
      padding: EdgeInsets.only(
        left: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
        right: isLarge ? 160 : (isMedium ? 80 : (isSmall ? 40 : 16)),
        top: 80,
        bottom: 80,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            decoration: BoxDecoration(
              color: const Color(0xFF0BDA50).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Sẵn Sàng Tối Ưu Hóa Nông Trại Của Bạn?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1.2,
                    letterSpacing: -0.015,
                  ),
                ),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: const Text(
                    'Tham gia cùng hàng ngàn nông dân hiện đại và đưa việc quản lý nông nghiệp của bạn lên một tầm cao mới. Bắt đầu dùng thử miễn phí ngay hôm nay.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Color(0xFF374151)),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0BDA50),
                    foregroundColor: const Color(0xFF111827),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  child: const Text('Bắt Đầu Sử Dụng Miễn Phí'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
