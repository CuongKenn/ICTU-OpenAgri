import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:openagri_app/viewmodels/login_viewmodel.dart';
import 'package:openagri_app/viewmodels/commodity_price_viewmodel.dart';
import 'package:openagri_app/views/login_view.dart';
import 'package:openagri_app/views/commodity_prices_list_view.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const AgriTechApp());
}

class AgriTechApp extends StatelessWidget {
  const AgriTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => CommodityPriceViewModel()),
      ],
      child: MaterialApp(
        title: 'AgriTech - Nông Nghiệp Thông Minh',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0BDA50),
            primary: const Color(0xFF0BDA50),
            background: const Color(0xFFF5F8F6),
          ),
          fontFamily: 'Inter',
          useMaterial3: true,
        ),
        home: const HomeScreen(),
        routes: {
          '/login': (context) => const LoginView(),
          '/commodity-prices': (context) => const CommodityPricesListView(),
        },
      ),
    );
  }
}
