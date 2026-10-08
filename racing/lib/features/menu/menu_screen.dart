import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:racing/app/router.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'MAIN MENU',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go(AppRoutes.setup),
              child: const Text('PLAY'),
            ),
          ],
        ),
      ),
    );
  }
}
