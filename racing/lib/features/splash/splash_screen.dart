import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) context.go(AppRoutes.menu);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'RACING GAME',
          style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
