import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/block_type.dart';
import 'package:vernonedu_entrepreneurship_app/features/block_coding/domain/entities/challenge.dart';

/// Sumber data lokal untuk challenge (hardcoded).
///
/// Tidak ada backend — semua data ada di sini.
class ChallengeLocalDatasource {
  static final ChallengeLocalDatasource _instance =
      ChallengeLocalDatasource._();
  factory ChallengeLocalDatasource() => _instance;
  ChallengeLocalDatasource._();

  List<ChallengeCategory> getCategories() => _categories;

  Challenge? getChallengeById(String id) {
    for (final cat in _categories) {
      for (final ch in cat.challenges) {
        if (ch.id == id) return ch;
      }
    }
    return null;
  }

  static final List<ChallengeCategory> _categories = [
    // ─────────────────────────────────────────────────────────
    // KATEGORI 1: Dasar-Dasar Pemrograman  (7 soal)
    // ─────────────────────────────────────────────────────────
    const ChallengeCategory(
      id: 'cat_basic',
      title: 'Dasar Pemrograman',
      description: 'Kenali blok-blok dasar dan buat program pertamamu!',
      emoji: '🚀',
      challenges: [
        // ── 1 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_hello',
          title: 'Hello, World!',
          description: 'Buat program yang menampilkan teks "Hello, World!" di layar.',
          hint: 'Gunakan blok Mulai → Tampilkan → Selesai. Isi teksnya dengan "Hello, World!"',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_basic',
          expectedOutput: ['Hello, World!'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
          ],
        ),
        // ── 2 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_two_lines',
          title: 'Dua Baris Teks',
          description:
              'Tampilkan dua baris teks: "Selamat Datang!" lalu "Belajar Coding Itu Seru!"',
          hint:
              'Susun dua blok Tampilkan secara berurutan, isi masing-masing dengan teks yang diminta.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_basic',
          expectedOutput: ['Selamat Datang!', 'Belajar Coding Itu Seru!'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
          ],
        ),
        // ── 3 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_greeting',
          title: 'Sapaan Nama',
          description:
              'Minta pengguna memasukkan namanya, lalu tampilkan "Halo, [nama]!".',
          hint:
              'Gunakan blok Minta Input untuk mendapatkan nama, lalu Tampilkan untuk menampilkan sapaannya.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_basic',
          expectedOutput: ['Masukkan nama: Budi', 'Halo, Budi!'],
          simulatedInputs: ['Budi'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
          ],
        ),
        // ── 4 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_biodata',
          title: 'Biodata Singkat',
          description:
              'Tampilkan tiga baris biodata: "Nama: Andi", "Kota: Bandung", "Umur: 17".',
          hint: 'Susun tiga blok Tampilkan berurutan. Isi langsung teksnya tanpa variabel.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_basic',
          expectedOutput: ['Nama: Andi', 'Kota: Bandung', 'Umur: 17'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
          ],
        ),
        // ── 5 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_calc_age',
          title: 'Hitung Umur',
          description:
              'Minta tahun lahir pengguna, lalu hitung dan tampilkan umurnya (tahun 2024).',
          hint:
              'Set Variabel tahun_sekarang = 2024. Minta input tahun_lahir. '
              'Kurang: tahun_sekarang - tahun_lahir = umur. Tampilkan umur.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_basic',
          expectedOutput: ['Masukkan tahun lahir: 2000', '24'],
          simulatedInputs: ['2000'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.setVarBlock,
            BlockType.mathSubBlock,
          ],
        ),
        // ── 6 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_square_perimeter',
          title: 'Keliling Persegi',
          description:
              'Set variabel sisi = 6, hitung keliling persegi (4 × sisi), lalu tampilkan hasilnya.',
          hint:
              'Set Variabel sisi = 6. Kali: sisi × 4 = keliling. Tampilkan keliling.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_basic',
          expectedOutput: ['24'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.mathMulBlock,
          ],
        ),
        // ── 7 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_triangle_area',
          title: 'Luas Segitiga',
          description:
              'Minta alas dan tinggi segitiga, hitung luasnya (alas × tinggi ÷ 2), tampilkan hasilnya.',
          hint:
              'Minta Input alas (simpan ke "alas") dan tinggi (simpan ke "tinggi"). '
              'Kali: alas × tinggi = temp. Bagi: temp ÷ 2 = luas. Tampilkan luas.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_basic',
          expectedOutput: ['Alas: 6', 'Tinggi: 4', '12'],
          simulatedInputs: ['6', '4'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.setVarBlock,
            BlockType.mathMulBlock,
            BlockType.mathDivBlock,
          ],
        ),
      ],
    ),

    // ─────────────────────────────────────────────────────────
    // KATEGORI 2: Pengulangan (7 soal)
    // ─────────────────────────────────────────────────────────
    const ChallengeCategory(
      id: 'cat_loop',
      title: 'Pengulangan',
      description: 'Kuasai loop untuk menjalankan instruksi berulang kali.',
      emoji: '🔄',
      challenges: [
        // ── 1 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_count_five',
          title: 'Hitung 1 sampai 5',
          description: 'Tampilkan angka 1, 2, 3, 4, 5 masing-masing di baris baru.',
          hint:
              'Set i = 1. Ulangi 5 kali: Tampilkan i, Ubah i sebesar +1.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_loop',
          expectedOutput: ['1', '2', '3', '4', '5'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.changeVarBlock,
            BlockType.repeatBlock,
          ],
        ),
        // ── 2 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_countdown',
          title: 'Hitung Mundur',
          description: 'Tampilkan angka 5, 4, 3, 2, 1 secara berurutan.',
          hint:
              'Set i = 5. Ulangi 5 kali: Tampilkan i, Ubah i sebesar -1.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_loop',
          expectedOutput: ['5', '4', '3', '2', '1'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.changeVarBlock,
            BlockType.repeatBlock,
          ],
        ),
        // ── 3 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_stars',
          title: 'Bintang Berjajar',
          description: 'Cetak simbol "*" sebanyak 5 baris.',
          hint:
              'Gunakan blok Ulangi 5 kali, di dalamnya Tampilkan "*".',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_loop',
          expectedOutput: ['*', '*', '*', '*', '*'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.repeatBlock,
          ],
        ),
        // ── 4 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_even_numbers',
          title: 'Angka Genap',
          description: 'Tampilkan 5 angka genap pertama: 2, 4, 6, 8, 10.',
          hint:
              'Set i = 2. Ulangi 5 kali: Tampilkan i, Ubah i sebesar +2.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_loop',
          expectedOutput: ['2', '4', '6', '8', '10'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.changeVarBlock,
            BlockType.repeatBlock,
          ],
        ),
        // ── 5 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_times_table',
          title: 'Tabel Perkalian 2',
          description: 'Tampilkan tabel perkalian 2 dari 2×1 hingga 2×5.',
          hint:
              'Set i = 1. Ulangi 5 kali: Kali 2 × i = hasil, Tampilkan hasil, Ubah i +1.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_loop',
          expectedOutput: ['2', '4', '6', '8', '10'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.changeVarBlock,
            BlockType.repeatBlock,
            BlockType.mathMulBlock,
          ],
        ),
        // ── 6 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_squares',
          title: 'Pangkat Dua',
          description: 'Tampilkan kuadrat dari angka 1 sampai 5: 1, 4, 9, 16, 25.',
          hint:
              'Set i = 1. Ulangi 5 kali: Kali i × i = kuadrat, Tampilkan kuadrat, Ubah i +1.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_loop',
          expectedOutput: ['1', '4', '9', '16', '25'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.changeVarBlock,
            BlockType.repeatBlock,
            BlockType.mathMulBlock,
          ],
        ),
        // ── 7 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_fizzbuzz',
          title: 'FizzBuzz',
          description:
              'Tampilkan angka 1-10. Jika habis dibagi 3 tampilkan "Fizz", habis dibagi 5 tampilkan "Buzz".',
          hint:
              'Gunakan kombinasi Ulangi, Jika, dan perbandingan untuk mendeteksi kelipatan 3 dan 5.',
          level: ChallengeLevel.advanced,
          categoryId: 'cat_loop',
          expectedOutput: [
            '1', '2', 'Fizz', '4', 'Buzz',
            'Fizz', '7', '8', 'Fizz', 'Buzz',
          ],
          allowedBlocks: BlockType.values,
        ),
      ],
    ),

    // ─────────────────────────────────────────────────────────
    // KATEGORI 3: Kondisi (7 soal)
    // ─────────────────────────────────────────────────────────
    const ChallengeCategory(
      id: 'cat_condition',
      title: 'Kondisi',
      description: 'Buat program yang bisa mengambil keputusan!',
      emoji: '🔀',
      challenges: [
        // ── 1 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_even_odd',
          title: 'Genap atau Ganjil',
          description:
              'Minta angka. Tampilkan "Genap" jika habis dibagi 2, "Ganjil" jika tidak.',
          hint:
              'Minta Input angka. Bandingkan: angka == 2, simpan ke cek. '
              'Jika/Lainnya: jika cek → Tampilkan "Genap", lainnya → "Ganjil".',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_condition',
          expectedOutput: ['Masukkan angka: 4', 'Genap'],
          simulatedInputs: ['4'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
          ],
        ),
        // ── 2 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_fever',
          title: 'Cek Suhu Tubuh',
          description:
              'Minta suhu tubuh. Tampilkan "Demam!" jika suhu > 37, atau "Normal" jika tidak.',
          hint:
              'Minta Input suhu. Bandingkan: suhu > 37, simpan ke cek. '
              'Jika/Lainnya: jika cek → "Demam!", lainnya → "Normal".',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_condition',
          expectedOutput: ['Suhu (°C): 38', 'Demam!'],
          simulatedInputs: ['38'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
          ],
        ),
        // ── 3 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_free_ticket',
          title: 'Tiket Gratis',
          description:
              'Minta umur pengunjung. Jika umur < 5, tampilkan "Tiket GRATIS!". Jika tidak, "Bayar Tiket".',
          hint:
              'Minta Input umur. Bandingkan: umur < 5, simpan ke cek. '
              'Jika/Lainnya: jika cek → "Tiket GRATIS!", lainnya → "Bayar Tiket".',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_condition',
          expectedOutput: ['Umur: 3', 'Tiket GRATIS!'],
          simulatedInputs: ['3'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
          ],
        ),
        // ── 4 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_pass_fail',
          title: 'Lulus atau Tidak',
          description:
              'Minta nilai ujian (0-100). Tampilkan "Selamat, Lulus!" jika nilai >= 70, atau "Belum Lulus" jika tidak.',
          hint:
              'Minta Input nilai. Bandingkan: nilai >= 70, simpan ke cek. '
              'Jika/Lainnya: jika cek → "Selamat, Lulus!", lainnya → "Belum Lulus".',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_condition',
          expectedOutput: ['Nilai: 80', 'Selamat, Lulus!'],
          simulatedInputs: ['80'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
          ],
        ),
        // ── 5 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_max_two',
          title: 'Nilai Terbesar',
          description:
              'Minta dua angka. Tampilkan angka yang lebih besar di antara keduanya.',
          hint:
              'Minta input a dan b. Bandingkan: a > b, simpan ke cek. '
              'Jika/Lainnya: jika cek → Tampilkan a, lainnya → Tampilkan b.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_condition',
          expectedOutput: ['Masukkan angka 1: 7', 'Masukkan angka 2: 3', '7'],
          simulatedInputs: ['7', '3'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
          ],
        ),
        // ── 6 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_same_three',
          title: 'Tiga Serangkai',
          description:
              'Minta tiga angka. Tampilkan "Sama semua!" jika ketiganya sama, atau "Berbeda" jika tidak.',
          hint:
              'Bandingkan a == b → ab_eq. Bandingkan b == c → bc_eq. '
              'DAN: ab_eq DAN bc_eq = all_eq. Jika/Lainnya: jika all_eq → "Sama semua!", lainnya → "Berbeda".',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_condition',
          expectedOutput: ['Angka 1: 5', 'Angka 2: 5', 'Angka 3: 5', 'Sama semua!'],
          simulatedInputs: ['5', '5', '5'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
            BlockType.andBlock,
          ],
        ),
        // ── 7 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_grade',
          title: 'Nilai Rapor',
          description:
              'Minta nilai (0-100). Tampilkan: A (≥90), B (≥75), C (≥60), atau D (di bawah 60).',
          hint:
              'Gunakan Bandingkan + beberapa Jika bertingkat. '
              'Bandingkan nilai >= 90 → cek_a. Jika cek_a: print "A". '
              'Bandingkan nilai >= 75 → cek_b. Jika cek_b: print "B". dst.',
          level: ChallengeLevel.advanced,
          categoryId: 'cat_condition',
          expectedOutput: ['Masukkan nilai: 85', 'B'],
          simulatedInputs: ['85'],
          allowedBlocks: BlockType.values,
        ),
      ],
    ),

    // ─────────────────────────────────────────────────────────
    // KATEGORI 4: Variabel & Matematika (7 soal)
    // ─────────────────────────────────────────────────────────
    const ChallengeCategory(
      id: 'cat_variables',
      title: 'Variabel & Matematika',
      description: 'Simpan data dan lakukan perhitungan dengan variabel.',
      emoji: '🔢',
      challenges: [
        // ── 1 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_add_two',
          title: 'Jumlahkan Dua Angka',
          description:
              'Minta dua angka dari pengguna, tambahkan, dan tampilkan hasilnya.',
          hint:
              'Minta input a dan b. Tambah: a + b = hasil. Tampilkan hasil.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_variables',
          expectedOutput: ['Masukkan angka 1: 5', 'Masukkan angka 2: 3', '8'],
          simulatedInputs: ['5', '3'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.mathAddBlock,
          ],
        ),
        // ── 2 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_rectangle_area',
          title: 'Luas Persegi Panjang',
          description:
              'Minta panjang dan lebar persegi panjang, hitung luasnya, lalu tampilkan.',
          hint:
              'Minta Input panjang dan lebar. Kali: panjang × lebar = luas. Tampilkan luas.',
          level: ChallengeLevel.beginner,
          categoryId: 'cat_variables',
          expectedOutput: ['Panjang: 8', 'Lebar: 5', '40'],
          simulatedInputs: ['8', '5'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.mathMulBlock,
          ],
        ),
        // ── 3 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_swap',
          title: 'Tukar Nilai',
          description:
              'Set variabel a = 5 dan b = 10, tukar nilainya, lalu tampilkan a dan b.',
          hint:
              'Butuh variabel sementara. Set temp = 5, a = 10, b = temp. Tampilkan a lalu b.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_variables',
          expectedOutput: ['10', '5'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
          ],
        ),
        // ── 4 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_average',
          title: 'Rata-Rata Tiga Angka',
          description:
              'Minta tiga angka, hitung rata-ratanya (jumlah ÷ 3), dan tampilkan hasilnya.',
          hint:
              'Minta input a, b, c. Tambah: a+b=ab, ab+c=total. Bagi: total÷3=rata. Tampilkan rata.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_variables',
          expectedOutput: ['Angka 1: 6', 'Angka 2: 8', 'Angka 3: 10', '8'],
          simulatedInputs: ['6', '8', '10'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.mathAddBlock,
            BlockType.mathDivBlock,
          ],
        ),
        // ── 5 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_convert_minutes',
          title: 'Konversi Menit ke Jam',
          description:
              'Minta jumlah menit, konversikan ke jam (menit ÷ 60), dan tampilkan hasilnya.',
          hint:
              'Minta Input menit. Bagi: menit ÷ 60 = jam. Tampilkan jam.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_variables',
          expectedOutput: ['Masukkan menit: 120', '2'],
          simulatedInputs: ['120'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.mathDivBlock,
          ],
        ),
        // ── 6 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_cube_surface',
          title: 'Luas Permukaan Kubus',
          description:
              'Minta panjang sisi kubus, hitung luas permukaannya (6 × sisi²), tampilkan hasilnya.',
          hint:
              'Minta Input sisi. Kali: sisi × sisi = kuadrat. Kali: kuadrat × 6 = luas. Tampilkan luas.',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_variables',
          expectedOutput: ['Sisi: 5', '150'],
          simulatedInputs: ['5'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.mathMulBlock,
          ],
        ),
        // ── 7 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_discount',
          title: 'Harga Setelah Diskon',
          description:
              'Set harga = 200 dan diskon = 10%. Hitung harga akhir setelah diskon, lalu tampilkan.',
          hint:
              'Set harga=200, persen=10. Kali: harga×persen=temp (2000). Bagi: temp÷100=diskon (20). '
              'Kurang: harga-diskon=bayar (180). Tampilkan bayar.',
          level: ChallengeLevel.advanced,
          categoryId: 'cat_variables',
          expectedOutput: ['180'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.setVarBlock,
            BlockType.mathMulBlock,
            BlockType.mathDivBlock,
            BlockType.mathSubBlock,
          ],
        ),
      ],
    ),

    // ─────────────────────────────────────────────────────────
    // KATEGORI 5: Logika (5 soal)
    // ─────────────────────────────────────────────────────────
    const ChallengeCategory(
      id: 'cat_logic',
      title: 'Logika',
      description: 'Kombinasikan kondisi dengan AND, OR, dan NOT.',
      emoji: '🧠',
      challenges: [
        // ── 1 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_logic_and',
          title: 'Keduanya Benar',
          description:
              'Minta dua angka. Tampilkan "Lolos!" jika kedua angka > 5, atau "Tidak Lolos" jika salah satu tidak.',
          hint:
              'Bandingkan a > 5 = cek_a. Bandingkan b > 5 = cek_b. DAN: cek_a DAN cek_b = lolos. '
              'Jika/Lainnya: jika lolos → "Lolos!", lainnya → "Tidak Lolos".',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_logic',
          expectedOutput: ['Angka 1: 7', 'Angka 2: 9', 'Lolos!'],
          simulatedInputs: ['7', '9'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
            BlockType.andBlock,
          ],
        ),
        // ── 2 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_logic_or',
          title: 'Salah Satu Benar',
          description:
              'Minta dua angka. Tampilkan "Ada yang genap!" jika salah satu atau keduanya genap.',
          hint:
              'Bandingkan a == 2 = cek_a. Bandingkan b == 2 = cek_b. '
              'ATAU: cek_a ATAU cek_b = ada_genap. Jika ada_genap → "Ada yang genap!", lainnya → "Tidak ada".',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_logic',
          expectedOutput: ['Angka 1: 4', 'Angka 2: 3', 'Ada yang genap!'],
          simulatedInputs: ['4', '3'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
            BlockType.orBlock,
          ],
        ),
        // ── 3 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_logic_not',
          title: 'Bukan Nol',
          description:
              'Minta angka. Tampilkan "Valid!" jika angka BUKAN nol, atau "Tidak Valid" jika nol.',
          hint:
              'Bandingkan angka == 0 = cek_nol. BUKAN: BUKAN cek_nol = valid. '
              'Jika/Lainnya: jika valid → "Valid!", lainnya → "Tidak Valid".',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_logic',
          expectedOutput: ['Masukkan angka: 7', 'Valid!'],
          simulatedInputs: ['7'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
            BlockType.notBlock,
          ],
        ),
        // ── 4 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_range_check',
          title: 'Dalam Rentang',
          description:
              'Minta angka. Tampilkan "Dalam rentang!" jika angka >= 10 DAN <= 20.',
          hint:
              'Bandingkan n >= 10 = cek_min. Bandingkan n <= 20 = cek_max. '
              'DAN: cek_min DAN cek_max = dalam. Jika/Lainnya: jika dalam → "Dalam rentang!", lainnya → "Di luar rentang".',
          level: ChallengeLevel.intermediate,
          categoryId: 'cat_logic',
          expectedOutput: ['Masukkan angka: 15', 'Dalam rentang!'],
          simulatedInputs: ['15'],
          allowedBlocks: [
            BlockType.start,
            BlockType.end,
            BlockType.printBlock,
            BlockType.askBlock,
            BlockType.ifElseBlock,
            BlockType.compareBlock,
            BlockType.andBlock,
          ],
        ),
        // ── 5 ──────────────────────────────────────────────
        Challenge(
          id: 'ch_login_sim',
          title: 'Simulasi Login',
          description:
              'Set variabel pin = 1234. Minta input pin. Tampilkan "Akses Diberikan!" jika pin benar, '
              'atau "Akses Ditolak!" jika salah.',
          hint:
              'Set Variabel pin=1234. Minta Input kode (simpan ke "kode"). '
              'Bandingkan: kode == pin = benar. Jika/Lainnya: jika benar → "Akses Diberikan!", lainnya → "Akses Ditolak!".',
          level: ChallengeLevel.advanced,
          categoryId: 'cat_logic',
          expectedOutput: ['Masukkan PIN: 1234', 'Akses Diberikan!'],
          simulatedInputs: ['1234'],
          allowedBlocks: BlockType.values,
        ),
      ],
    ),
  ];
}
