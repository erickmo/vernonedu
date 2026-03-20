import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_page.dart';
import '../../features/hubungi/hubungi_page.dart';
import '../../features/kursus/kursus_page.dart';
import '../../features/update/update_page.dart';

/// Router utama aplikasi website VernonEdu.
class AppRouter {
  AppRouter._();

  static const String home = '/';
  static const String kursus = '/kursus';
  static const String update = '/update';
  static const String hubungi = '/hubungi';

  static final router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: kursus,
        name: 'kursus',
        builder: (context, state) => const KursusPage(),
      ),
      GoRoute(
        path: update,
        name: 'update',
        builder: (context, state) => const UpdatePage(),
      ),
      GoRoute(
        path: hubungi,
        name: 'hubungi',
        builder: (context, state) => const HubungiPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '404',
              style: TextStyle(
                color: Color(0xFF7C68EE),
                fontSize: 80,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Halaman tidak ditemukan',
              style: TextStyle(color: Color(0xFF5A4A7A), fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go(home),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C68EE),
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali ke Beranda',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
