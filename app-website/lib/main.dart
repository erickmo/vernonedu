import 'package:flutter/material.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const VernonEduApp());
}

/// Root widget VernonEdu Website.
class VernonEduApp extends StatelessWidget {
  const VernonEduApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'VernonEdu — Platform Edukasi Wirausaha Terdepan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
