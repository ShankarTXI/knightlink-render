import 'package:flutter/material.dart';

import 'app_theme.dart';
import '../features/home/home_screen.dart';

class KnightLinkApp extends StatelessWidget {
  const KnightLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KnightLink Chess',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: const HomeScreen(),
    );
  }
}
