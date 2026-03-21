import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/quest_entity.dart';

/// Halaman daftar misi.
class QuestPage extends StatefulWidget {
  const QuestPage({super.key});

  @override
  State<QuestPage> createState() => _QuestPageState();
}

class _QuestPageState extends State<QuestPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mock data
  static final _mockQuests = [
    QuestEntity(
      id: '1',
      title: 'Baca Buku 15 Menit',
      description: 'Pilih buku favoritmu dan baca minimal 15 menit hari ini!',
      category: QuestCategory.academic,
      status: QuestStatus.active,
      pointsReward: 10,
      xpReward: 20,
      durationMinutes: 15,
      iconEmoji: '📚',
      steps: ['Pilih buku', 'Cari tempat nyaman', 'Baca 15 menit', 'Ceritakan ke orang tua'],
    ),
    QuestEntity(
      id: '2',
      title: 'Bantuin Cuci Piring',
      description: 'Bantu orang tua mencuci piring setelah makan!',
      category: QuestCategory.responsibility,
      status: QuestStatus.active,
      pointsReward: 15,
      xpReward: 25,
      durationMinutes: 10,
      iconEmoji: '🍽️',
      steps: ['Kumpulkan piring kotor', 'Sabuni dan cuci', 'Bilas dengan air bersih', 'Keringkan'],
    ),
    QuestEntity(
      id: '3',
      title: 'Gambar Bebas',
      description: 'Ekspresikan kreativitasmu dengan menggambar apapun yang kamu suka!',
      category: QuestCategory.creativity,
      status: QuestStatus.completed,
      pointsReward: 12,
      xpReward: 22,
      durationMinutes: 20,
      iconEmoji: '🎨',
      steps: ['Siapkan kertas dan pensil warna', 'Gambar imajinasimu', 'Tunjukkan ke keluarga'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppDimensions.spacingM,
                AppDimensions.spacingM,
                AppDimensions.spacingM,
                0,
              ),
              child: Text(AppStrings.quests, style: AppTextStyles.headingL),
            ),

            const SizedBox(height: AppDimensions.spacingM),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacingM,
              ),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusCircle),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusCircle),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTextStyles.labelL,
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: AppStrings.activeQuest),
                    Tab(text: AppStrings.completedQuest),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppDimensions.spacingM),

            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQuestList(
                    _mockQuests
                        .where((q) => q.status == QuestStatus.active)
                        .toList(),
                  ),
                  _buildQuestList(
                    _mockQuests
                        .where((q) => q.status == QuestStatus.completed)
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestList(List<QuestEntity> quests) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: AppDimensions.spacingM),
            Text(AppStrings.emptyQuests, style: AppTextStyles.bodyL),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingM),
      itemCount: quests.length,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.spacingS),
      itemBuilder: (context, i) => _QuestCard(
        quest: quests[i],
        onTap: () => context.push('${AppRoutes.quests}/${quests[i].id}'),
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  final QuestEntity quest;
  final VoidCallback onTap;

  const _QuestCard({required this.quest, required this.onTap});

  Color get _categoryColor {
    return switch (quest.category) {
      QuestCategory.academic => AppColors.primary,
      QuestCategory.social => AppColors.funTeal,
      QuestCategory.health => AppColors.accent,
      QuestCategory.creativity => AppColors.funPurple,
      QuestCategory.responsibility => AppColors.secondary,
      QuestCategory.daily => AppColors.funOrange,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.spacingM),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          border: Border.all(color: AppColors.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusM),
              ),
              child: Center(
                child: Text(
                  quest.iconEmoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
            ),

            const SizedBox(width: AppDimensions.spacingM),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(quest.title, style: AppTextStyles.labelL),
                  const SizedBox(height: AppDimensions.spacingXS),
                  Text(
                    quest.description,
                    style: AppTextStyles.bodyS,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDimensions.spacingS),
                  Row(
                    children: [
                      _buildTag(
                        '⭐ ${quest.pointsReward} poin',
                        AppColors.secondary,
                      ),
                      const SizedBox(width: AppDimensions.spacingXS),
                      _buildTag(
                        '⏱ ${quest.durationMinutes} menit',
                        AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (quest.isCompleted)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.accent,
                size: 28,
              )
            else
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.spacingS,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelS.copyWith(color: color),
      ),
    );
  }
}
