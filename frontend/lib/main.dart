import 'package:flutter/material.dart';
import 'package:openagri_app/viewmodels/login_viewmodel.dart';
import 'package:openagri_app/views/login_view.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OpenAgri',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.white,
      ),
      home: ChangeNotifierProvider(
        create: (_) => LoginViewModel(),
        child: const LoginView(),
      ),
    );
  }
}
