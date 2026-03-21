import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vernonedu_blockcoding/core/di/injection.dart';
import 'package:vernonedu_blockcoding/core/router/app_router.dart';
import 'package:vernonedu_blockcoding/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientasi ke portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Setup UI overlay
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Setup dependency injection
  await setupDependencies();

  runApp(const BlockCodeApp());
}

/// Root widget aplikasi VernonEdu BlockCode.
class BlockCodeApp extends StatelessWidget {
  const BlockCodeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BlockCode — VernonEdu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
    );
  }
}
