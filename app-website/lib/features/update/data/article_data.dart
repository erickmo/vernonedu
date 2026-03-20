import 'package:flutter/material.dart';

/// Model data artikel/blog VernonEdu.
class ArticleModel {
  final String id;
  final String title;
  final String excerpt;
  final String category;
  final String author;
  final String authorInitial;
  final String date;
  final String readTime;
  final Color color;
  final IconData icon;
  final bool isFeatured;
  final List<String> tags;

  const ArticleModel({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.category,
    required this.author,
    required this.authorInitial,
    required this.date,
    required this.readTime,
    required this.color,
    required this.icon,
    this.isFeatured = false,
    required this.tags,
  });
}

/// Data statis artikel — dalam produksi ini akan dari API.
class ArticleData {
  ArticleData._();

  static const List<ArticleModel> articles = [
    ArticleModel(
      id: '1',
      title: '10 Strategi Digital Marketing yang Terbukti Meningkatkan Penjualan UMKM',
      excerpt:
          'Di era digital ini, strategi pemasaran online bukan lagi pilihan — ini adalah kebutuhan. Pelajari 10 strategi yang telah terbukti membantu ribuan UMKM Indonesia meningkatkan omset mereka secara signifikan.',
      category: 'MARKETING',
      author: 'Sarah Wijaya',
      authorInitial: 'SW',
      date: '18 Maret 2026',
      readTime: '8 menit',
      color: Color(0xFF4F46E5),
      icon: Icons.trending_up_rounded,
      isFeatured: true,
      tags: ['Digital Marketing', 'UMKM', 'Penjualan'],
    ),
    ArticleModel(
      id: '2',
      title: 'Cara Mengelola Keuangan Bisnis untuk Pemula: Panduan Lengkap 2026',
      excerpt:
          'Banyak bisnis yang gagal bukan karena produknya buruk, tapi karena manajemen keuangan yang tidak tepat. Panduan ini akan membantu Anda memahami dasar-dasar keuangan bisnis.',
      category: 'KEUANGAN',
      author: 'Dr. Ahmad Fauzi',
      authorInitial: 'AF',
      date: '15 Maret 2026',
      readTime: '12 menit',
      color: Color(0xFF10B981),
      icon: Icons.account_balance_rounded,
      isFeatured: true,
      tags: ['Keuangan', 'Pemula', 'Manajemen'],
    ),
    ArticleModel(
      id: '3',
      title: 'Dari 0 ke Rp 100 Juta: Kisah Sukses Alumni VernonEdu yang Menginspirasi',
      excerpt:
          'Andi Prasetyo memulai bisnis kuliner online-nya dengan modal Rp 2 juta. Setahun setelah mengikuti program VernonEdu, revenue bulanannya mencapai Rp 100 juta. Ini kisah lengkapnya.',
      category: 'SUCCESS STORY',
      author: 'Tim VernonEdu',
      authorInitial: 'VE',
      date: '12 Maret 2026',
      readTime: '6 menit',
      color: Color(0xFFF59E0B),
      icon: Icons.emoji_events_rounded,
      isFeatured: false,
      tags: ['Kisah Sukses', 'Alumni', 'Inspirasi'],
    ),
    ArticleModel(
      id: '4',
      title: 'Business Model Canvas: Cara Mudah Merancang Bisnis yang Sustainable',
      excerpt:
          'Business Model Canvas adalah alat yang powerful untuk merancang dan mengkomunikasikan model bisnis Anda. Pelajari cara menggunakannya dengan efektif dalam artikel ini.',
      category: 'STRATEGI',
      author: 'Hendro Kusuma',
      authorInitial: 'HK',
      date: '10 Maret 2026',
      readTime: '10 menit',
      color: Color(0xFF7C3AED),
      icon: Icons.dashboard_customize_rounded,
      isFeatured: false,
      tags: ['BMC', 'Strategi', 'Bisnis'],
    ),
    ArticleModel(
      id: '5',
      title: 'Tren E-Commerce 2026: Apa yang Harus Dipersiapkan Pengusaha Online?',
      excerpt:
          'Lanskap e-commerce terus berubah dengan cepat. Dari live shopping hingga social commerce, ini adalah tren yang wajib Anda pahami untuk tetap kompetitif di 2026.',
      category: 'E-COMMERCE',
      author: 'Rizky Pratama',
      authorInitial: 'RP',
      date: '8 Maret 2026',
      readTime: '9 menit',
      color: Color(0xFF0EA5E9),
      icon: Icons.shopping_bag_rounded,
      isFeatured: false,
      tags: ['E-Commerce', 'Tren', '2026'],
    ),
    ArticleModel(
      id: '6',
      title: 'Leadership di Era Modern: Memimpin Tim yang Produktif dan Bahagia',
      excerpt:
          'Kepemimpinan yang efektif bukan tentang otoritas — ini tentang inspirasi. Pelajari prinsip-prinsip kepemimpinan modern yang akan membantu Anda membangun tim yang solid dan termotivasi.',
      category: 'LEADERSHIP',
      author: 'Prof. Siti Aminah',
      authorInitial: 'SA',
      date: '5 Maret 2026',
      readTime: '11 menit',
      color: Color(0xFFEC4899),
      icon: Icons.psychology_rounded,
      isFeatured: false,
      tags: ['Leadership', 'Tim', 'Manajemen'],
    ),
    ArticleModel(
      id: '7',
      title: 'VernonEdu Luncurkan 5 Kursus Baru — Ini yang Wajib Anda Coba!',
      excerpt:
          'Kami dengan bangga mengumumkan peluncuran 5 kursus baru yang dirancang khusus untuk memenuhi kebutuhan pengusaha Indonesia di 2026. Dari AI untuk Bisnis hingga Ekspor-Impor.',
      category: 'ANNOUNCEMENT',
      author: 'Tim VernonEdu',
      authorInitial: 'VE',
      date: '1 Maret 2026',
      readTime: '4 menit',
      color: Color(0xFF14B8A6),
      icon: Icons.campaign_rounded,
      isFeatured: false,
      tags: ['Kursus Baru', 'Pengumuman'],
    ),
    ArticleModel(
      id: '8',
      title: 'Cara Memulai Bisnis Online dengan Modal Minimum di 2026',
      excerpt:
          'Tidak punya modal besar? Bukan halangan! Dengan strategi yang tepat, Anda bisa memulai bisnis online yang menguntungkan dengan modal di bawah Rp 5 juta.',
      category: 'BISNIS DASAR',
      author: 'Budi Hartono',
      authorInitial: 'BH',
      date: '25 Februari 2026',
      readTime: '7 menit',
      color: Color(0xFF6366F1),
      icon: Icons.lightbulb_rounded,
      isFeatured: false,
      tags: ['Modal Kecil', 'Bisnis Online', 'Pemula'],
    ),
  ];

  static const List<String> categories = [
    'Semua',
    'Marketing',
    'Keuangan',
    'Strategi',
    'E-Commerce',
    'Leadership',
    'Success Story',
    'Announcement',
  ];
}
