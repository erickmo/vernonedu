# PRD: MCB Junior

**Versi:** 1.0.0
**Tanggal:** 2026-03-20
**Status:** Active
**Stack:** Flutter Web (PWA)
**Platform:** Web (Mobile Browser + Installable PWA)
**Author:** AI-Generated

---

## 1. Overview

### 1.1 Latar Belakang
Anak-anak membutuhkan alat bantu yang menyenangkan untuk membangun kebiasaan baik dan mindset positif sejak dini. MCB Junior hadir sebagai aplikasi gamifikasi yang mengubah tugas harian dan kebiasaan baik menjadi misi seru dengan reward menarik.

### 1.2 Tujuan Produk
- Membantu anak membangun kebiasaan baik melalui check-in harian
- Memberikan motivasi melalui sistem poin, level, dan streak
- Mempermudah orang tua memantau dan mengelola perkembangan anak
- Menjadikan proses belajar dan bertumbuh sebagai permainan yang menyenangkan

### 1.3 Target Pengguna
| Role | Deskripsi |
|---|---|
| Anak (6-12 tahun) | Pengguna utama — mengerjakan misi, cek-in habit, tukar reward |
| Orang Tua | Membuat akun, mengelola quest & reward, memantau progress |

---

## 2. Fitur Utama

| Fitur | Prioritas | Status |
|---|---|---|
| Onboarding & Login | High | 🟡 In Progress |
| Dashboard (XP, Streak, Stats) | High | 🟡 In Progress |
| Quest / Misi | High | 🟡 In Progress |
| Habit / Kebiasaan Harian | High | 🟡 In Progress |
| Reward / Hadiah | High | 🟡 In Progress |
| Profil Anak | Medium | 🟡 In Progress |
| Leaderboard | Medium | 🔴 Belum Mulai |
| Notifikasi Pengingat | Low | 🔴 Belum Mulai |
| Parent Dashboard | Low | 🔴 Belum Mulai |

---

## 3. Screen & Navigation

| Screen | Route | Deskripsi | Auth |
|---|---|---|---|
| OnboardingPage | /onboarding | Intro 3 slide, hanya sekali | No |
| LoginPage | /login | Form masuk | No |
| DashboardPage | /dashboard | Ringkasan XP, streak, misi hari ini | Yes |
| QuestPage | /quests | Daftar misi aktif & selesai | Yes |
| QuestDetailPage | /quests/:id | Detail misi + langkah-langkah | Yes |
| HabitPage | /habits | Check-in kebiasaan harian + chart | Yes |
| RewardPage | /rewards | Katalog hadiah + tukar poin | Yes |
| ProfilePage | /profile | Data anak, badge, logout | Yes |

---

## 4. Sistem Gamifikasi

### 4.1 Poin & XP
- Setiap misi selesai → poin + XP
- Setiap habit check-in → poin kecil
- Poin bisa ditukar reward
- XP digunakan untuk naik level (tidak bisa ditukar)

### 4.2 Level System
| Level | Nama | XP Dibutuhkan |
|---|---|---|
| 1 | Pemula | 0 |
| 2 | Pelajar | 100 |
| 3 | Penjelajah | 250 |
| 4 | Petualang | 500 |
| 5 | Pejuang | 1000 |
| 6 | Pahlawan | 2000 |
| 7 | Legenda | 5000 |

### 4.3 Streak
- Dihitung berdasarkan hari berturut-turut melakukan minimal 1 check-in habit
- Bonus poin tiap 7 hari streak
- Streak hilang jika tidak check-in dalam 1 hari

### 4.4 Badge / Lencana
- Otomatis unlock berdasarkan pencapaian
- Contoh: "7 Hari Streak", "10 Misi Selesai", "Pembaca Rajin"

---

## 5. Kategori Quest

| Kategori | Emoji | Contoh |
|---|---|---|
| Akademik | 📚 | Baca buku, belajar matematika |
| Sosial | 🤝 | Bantu teman, telepon nenek |
| Kesehatan | 💪 | Olahraga, makan sayur |
| Kreativitas | 🎨 | Menggambar, menulis cerita |
| Tanggung Jawab | 🏠 | Cuci piring, rapikan kamar |
| Harian | ⭐ | Quest berulang setiap hari |

---

## 6. Kategori Reward

| Kategori | Contoh |
|---|---|
| Hak Istimewa | Main game extra, tidur lebih malam |
| Hadiah Fisik | Mainan, buku, alat tulis |
| Pengalaman | Nonton bioskop, piknik |
| Digital | Badge, wallpaper, avatar baru |

---

## 7. Non-Functional Requirements

| Kategori | Target |
|---|---|
| Load time (cold start) | < 3 detik (4G) |
| Installable PWA | Ya (Android + iOS) |
| Offline support | Halaman dashboard & habit (cached) |
| Min screen width | 320px |
| Max content width | 480px (mobile-first) |
| Test coverage | ≥ 70% (Cubit & Domain) |
| Aksesibilitas | Font min 14px, kontras WCAG AA |

---

## 8. Out of Scope (v1.0)
- Multi-bahasa (selain Bahasa Indonesia)
- Fitur sosial antar anak
- Live leaderboard real-time
- Parent mobile app terpisah

---

## 9. Open Questions
- [ ] Apakah anak perlu verifikasi email atau cukup username+password?
- [ ] Berapa batas maksimum quest aktif per anak?
- [ ] Apakah reward perlu approval orang tua sebelum bisa ditukar?

---
*PRD versi 1.0 — update sesuai perkembangan sprint.*
