import 'package:flutter/material.dart';
import 'package:racing/app/router.dart';
import 'package:racing/app/theme.dart';


class RacingApp extends StatelessWidget {
  const RacingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Racing Game',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
