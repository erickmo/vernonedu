import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/enrollment/enrollment_page.dart';
import '../../features/home/home_page.dart';
import '../../features/hubungi/hubungi_page.dart';
import '../../features/katalog/batch_detail_page.dart';
import '../../features/katalog/course_detail_page.dart';
import '../../features/katalog/katalog_page.dart';
import '../../features/program/karir_page.dart';
import '../../features/program/privat_page.dart';
import '../../features/program/reguler_page.dart';
import '../../features/program/sertifikasi_page.dart';
import '../../features/segment/individu_page.dart';
import '../../features/segment/korporat_page.dart';
import '../../features/segment/sekolah_page.dart';
import '../../features/segment/universitas_page.dart';
import '../../features/sertifikat/sertifikat_page.dart';
import '../../features/update/article_detail_page.dart';
import '../../features/update/update_page.dart';

/// Router utama VernonEdu Website.
/// All routes defined in CLAUDE.md are registered here.
class AppRouter {
  AppRouter._();

  // ─── Route paths ────────────────────────────────────────────────────────────
  static const String home = '/';

  // Program
  static const String programKarir = '/program/karir';
  static const String programReguler = '/program/reguler';
  static const String programPrivat = '/program/privat';
  static const String programSertifikasi = '/program/sertifikasi';

  // Untuk (segments)
  static const String untukUniversitas = '/untuk/universitas';
  static const String untukSekolah = '/untuk/sekolah';
  static const String untukKorporat = '/untuk/korporat';
  static const String untukIndividu = '/untuk/individu';

  // Katalog
  static const String katalog = '/katalog';
  static const String katalogDetail = '/katalog/:courseId';
  static const String batchDetail = '/katalog/:courseId/batch/:batchId';

  // Enrollment
  static const String daftar = '/daftar';
  static const String daftarBatch = '/daftar/:batchId';

  // Certificate verification
  static const String sertifikat = '/sertifikat/:code';

  // Content
  static const String update = '/update';
  static const String hubungi = '/hubungi';

  // Legacy (backward compat)
  static const String kursus = '/kursus';

  // ─── Router ─────────────────────────────────────────────────────────────────
  static final router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: false,
    routes: [
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomePage(),
      ),

      // ─── Program pages ───────────────────────────────────────────────────
      GoRoute(
        path: programKarir,
        name: 'program-karir',
        builder: (context, state) => const ProgramKarirPage(),
      ),
      GoRoute(
        path: programReguler,
        name: 'program-reguler',
        builder: (context, state) => const ProgramRegulerPage(),
      ),
      GoRoute(
        path: programPrivat,
        name: 'program-privat',
        builder: (context, state) => const ProgramPrivatPage(),
      ),
      GoRoute(
        path: programSertifikasi,
        name: 'program-sertifikasi',
        builder: (context, state) => const ProgramSertifikasiPage(),
      ),

      // ─── Segment pages ───────────────────────────────────────────────────
      GoRoute(
        path: untukUniversitas,
        name: 'untuk-universitas',
        builder: (context, state) => const SegmentUniversitasPage(),
      ),
      GoRoute(
        path: untukSekolah,
        name: 'untuk-sekolah',
        builder: (context, state) => const SegmentSekolahPage(),
      ),
      GoRoute(
        path: untukKorporat,
        name: 'untuk-korporat',
        builder: (context, state) => const SegmentKorporatPage(),
      ),
      GoRoute(
        path: untukIndividu,
        name: 'untuk-individu',
        builder: (context, state) => const SegmentIndividuPage(),
      ),

      // ─── Katalog ─────────────────────────────────────────────────────────
      GoRoute(
        path: katalog,
        name: 'katalog',
        builder: (context, state) => const KatalogPage(),
      ),
      GoRoute(
        path: '/katalog/:courseId',
        name: 'course-detail',
        builder: (context, state) =>
            CourseDetailPage(courseId: state.pathParameters['courseId']!),
      ),
      GoRoute(
        path: '/katalog/:courseId/batch/:batchId',
        name: 'batch-detail',
        builder: (context, state) => BatchDetailPage(
          courseId: state.pathParameters['courseId']!,
          batchId: state.pathParameters['batchId']!,
        ),
      ),

      // ─── Enrollment ──────────────────────────────────────────────────────
      GoRoute(
        path: '/daftar/:batchId',
        name: 'enrollment',
        builder: (context, state) =>
            EnrollmentPage(batchId: state.pathParameters['batchId']!),
      ),

      // ─── Certificate verification ────────────────────────────────────────
      GoRoute(
        path: '/sertifikat',
        name: 'sertifikat-input',
        builder: (context, state) => const SertifikatPage(code: ''),
      ),
      GoRoute(
        path: '/sertifikat/:code',
        name: 'sertifikat',
        builder: (context, state) =>
            SertifikatPage(code: state.pathParameters['code']!),
      ),

      // ─── Content ─────────────────────────────────────────────────────────
      GoRoute(
        path: update,
        name: 'update',
        builder: (context, state) => const UpdatePage(),
      ),
      GoRoute(
        path: '/update/:slug',
        name: 'article-detail',
        builder: (context, state) =>
            ArticleDetailPage(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: hubungi,
        name: 'hubungi',
        builder: (context, state) => const HubungiPage(),
      ),

      // ─── Legacy redirect ─────────────────────────────────────────────────
      GoRoute(
        path: kursus,
        name: 'kursus',
        redirect: (context, _) => katalog,
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
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

