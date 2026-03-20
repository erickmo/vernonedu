import 'package:flutter/material.dart';

/// Model data kursus VernonEdu.
class CourseModel {
  final String id;
  final String title;
  final String category;
  final String instructor;
  final String instructorInitial;
  final double rating;
  final int students;
  final String duration;
  final String level;
  final String price;
  final String? originalPrice;
  final List<Color> gradientColors;
  final IconData icon;
  final bool isBestseller;
  final String description;
  final List<String> topics;

  const CourseModel({
    required this.id,
    required this.title,
    required this.category,
    required this.instructor,
    required this.instructorInitial,
    required this.rating,
    required this.students,
    required this.duration,
    required this.level,
    required this.price,
    this.originalPrice,
    required this.gradientColors,
    required this.icon,
    this.isBestseller = false,
    required this.description,
    required this.topics,
  });
}

/// Data statis kursus — dalam produksi ini akan dari API.
class CourseData {
  CourseData._();

  static const List<CourseModel> courses = [
    CourseModel(
      id: '1',
      title: 'Membangun Bisnis dari Nol',
      category: 'BISNIS DASAR',
      instructor: 'Budi Hartono, MBA',
      instructorInitial: 'BH',
      rating: 4.9,
      students: 3420,
      duration: '24 jam',
      level: 'Pemula',
      price: 'Rp 499.000',
      originalPrice: 'Rp 999.000',
      gradientColors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
      icon: Icons.rocket_launch_rounded,
      isBestseller: true,
      description:
          'Pelajari cara membangun bisnis yang sukses dari nol dengan panduan langkah demi langkah. Dari ide, validasi pasar, hingga monetisasi.',
      topics: [
        'Validasi Ide Bisnis',
        'Riset Pasar',
        'Business Model Canvas',
        'Branding & Identitas',
        'Strategi Pemasaran Awal',
        'Keuangan Awal Bisnis',
      ],
    ),
    CourseModel(
      id: '2',
      title: 'Digital Marketing untuk Pengusaha',
      category: 'MARKETING',
      instructor: 'Sarah Wijaya, MSc',
      instructorInitial: 'SW',
      rating: 4.8,
      students: 2810,
      duration: '18 jam',
      level: 'Pemula',
      price: 'Rp 399.000',
      originalPrice: 'Rp 799.000',
      gradientColors: [Color(0xFF0EA5E9), Color(0xFF6366F1)],
      icon: Icons.campaign_rounded,
      isBestseller: true,
      description:
          'Kuasai strategi pemasaran digital untuk mengembangkan bisnis Anda secara online. SEO, Social Media, Email Marketing, dan Paid Ads.',
      topics: [
        'SEO & Content Marketing',
        'Social Media Marketing',
        'Google & Meta Ads',
        'Email Marketing',
        'Analytics & Data',
        'Conversion Optimization',
      ],
    ),
    CourseModel(
      id: '3',
      title: 'Manajemen Keuangan Bisnis',
      category: 'KEUANGAN',
      instructor: 'Dr. Ahmad Fauzi, CFA',
      instructorInitial: 'AF',
      rating: 4.9,
      students: 1940,
      duration: '16 jam',
      level: 'Menengah',
      price: 'Rp 599.000',
      originalPrice: 'Rp 1.199.000',
      gradientColors: [Color(0xFF10B981), Color(0xFF0D9488)],
      icon: Icons.account_balance_rounded,
      isBestseller: false,
      description:
          'Kelola keuangan bisnis Anda dengan cerdas. Laporan keuangan, arus kas, investasi, dan perencanaan keuangan jangka panjang.',
      topics: [
        'Laporan Keuangan Dasar',
        'Manajemen Arus Kas',
        'Pricing Strategy',
        'Break Even Analysis',
        'Perencanaan Pajak UMKM',
        'Investasi & Ekspansi',
      ],
    ),
    CourseModel(
      id: '4',
      title: 'E-Commerce Strategy & Operations',
      category: 'E-COMMERCE',
      instructor: 'Rizky Pratama, MBA',
      instructorInitial: 'RP',
      rating: 4.7,
      students: 2230,
      duration: '20 jam',
      level: 'Menengah',
      price: 'Rp 549.000',
      originalPrice: 'Rp 1.099.000',
      gradientColors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
      icon: Icons.shopping_cart_rounded,
      isBestseller: false,
      description:
          'Bangun dan skalakan bisnis e-commerce Anda. Dari setup toko online, manajemen produk, hingga strategi ekspansi marketplace.',
      topics: [
        'Setup Toko Online',
        'Manajemen Produk & Katalog',
        'Strategi Marketplace',
        'Logistik & Fulfillment',
        'Customer Service Excellence',
        'Skalasi Bisnis E-commerce',
      ],
    ),
    CourseModel(
      id: '5',
      title: 'Leadership & Tim Management',
      category: 'LEADERSHIP',
      instructor: 'Prof. Siti Aminah, PhD',
      instructorInitial: 'SA',
      rating: 4.9,
      students: 1680,
      duration: '15 jam',
      level: 'Menengah',
      price: 'Rp 699.000',
      originalPrice: 'Rp 1.399.000',
      gradientColors: [Color(0xFFEC4899), Color(0xFF8B5CF6)],
      icon: Icons.groups_rounded,
      isBestseller: false,
      description:
          'Kembangkan kemampuan kepemimpinan dan bangun tim yang solid. Dari rekrutmen, manajemen performa, hingga budaya perusahaan.',
      topics: [
        'Gaya Kepemimpinan Efektif',
        'Rekrutmen & Onboarding',
        'Performance Management',
        'Komunikasi & Delegasi',
        'Resolusi Konflik',
        'Budaya Perusahaan',
      ],
    ),
    CourseModel(
      id: '6',
      title: 'Business Model Canvas & Strategy',
      category: 'STRATEGI',
      instructor: 'Hendro Kusuma, CPA',
      instructorInitial: 'HK',
      rating: 4.8,
      students: 1490,
      duration: '12 jam',
      level: 'Pemula',
      price: 'Rp 349.000',
      originalPrice: 'Rp 699.000',
      gradientColors: [Color(0xFF14B8A6), Color(0xFF0EA5E9)],
      icon: Icons.dashboard_customize_rounded,
      isBestseller: false,
      description:
          'Rancang strategi bisnis yang kuat menggunakan Business Model Canvas, Value Proposition, dan analisis kompetitif yang mendalam.',
      topics: [
        'Business Model Canvas',
        'Value Proposition Design',
        'Competitive Analysis',
        'SWOT & Porter Five Forces',
        'Blue Ocean Strategy',
        'Strategic Planning',
      ],
    ),
  ];

  static const List<String> categories = [
    'Semua',
    'Bisnis Dasar',
    'Marketing',
    'Keuangan',
    'E-Commerce',
    'Leadership',
    'Strategi',
  ];
}
