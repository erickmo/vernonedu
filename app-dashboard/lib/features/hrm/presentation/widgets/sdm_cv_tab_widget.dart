import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/sdm_entity.dart';

/// Tab CV & Resume SDM — ringkasan, pendidikan, pengalaman, skill, sertifikasi.
class SdmCvTabWidget extends StatelessWidget {
  final SdmResumeEntity resume;

  const SdmCvTabWidget({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (resume.summary != null) ...[
            _buildSection(
              context,
              icon: Icons.person_outlined,
              title: AppStrings.sdmCvSummary,
              child: _buildSummary(context),
            ),
            const SizedBox(height: AppDimensions.lg),
          ],
          _buildLinksRow(context),
          const SizedBox(height: AppDimensions.lg),
          _buildSection(
            context,
            icon: Icons.school_outlined,
            title: AppStrings.sdmCvEducation,
            child: _buildEducationList(context),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildSection(
            context,
            icon: Icons.work_outline,
            title: AppStrings.sdmCvWorkExperience,
            child: _buildWorkList(context),
          ),
          const SizedBox(height: AppDimensions.lg),
          _buildSection(
            context,
            icon: Icons.psychology_outlined,
            title: AppStrings.sdmCvSkills,
            child: _buildSkillsWrap(context),
          ),
          if (resume.certifications.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.lg),
            _buildSection(
              context,
              icon: Icons.verified_outlined,
              title: AppStrings.sdmCvCertifications,
              child: _buildCertificationList(context),
            ),
          ],
          if (resume.languages.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.lg),
            _buildSection(
              context,
              icon: Icons.language_outlined,
              title: AppStrings.sdmCvLanguages,
              child: _buildLanguageList(context),
            ),
          ],
          const SizedBox(height: AppDimensions.xl),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget child,
  }) =>
      Container(
        padding: const EdgeInsets.all(AppDimensions.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: AppDimensions.iconMd, color: AppColors.primary),
                const SizedBox(width: AppDimensions.sm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.md),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: AppDimensions.md),
            child,
          ],
        ),
      );

  Widget _buildSummary(BuildContext context) => Text(
        resume.summary!,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
      );

  Widget _buildLinksRow(BuildContext context) {
    final links = <_LinkItem>[];
    if (resume.linkedInUrl != null) {
      links.add(_LinkItem(Icons.link, 'LinkedIn', resume.linkedInUrl!));
    }
    if (resume.githubUrl != null) {
      links.add(_LinkItem(Icons.code, 'GitHub', resume.githubUrl!));
    }
    if (resume.portfolioUrl != null) {
      links.add(_LinkItem(Icons.open_in_new, 'Portfolio', resume.portfolioUrl!));
    }
    if (links.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimensions.sm,
      children: links.map((l) => _buildLinkChip(context, l)).toList(),
    );
  }

  Widget _buildLinkChip(BuildContext context, _LinkItem item) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.infoSurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.info.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: AppDimensions.iconSm, color: AppColors.info),
            const SizedBox(width: AppDimensions.xs),
            Text(
              item.label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ),
      );

  Widget _buildEducationList(BuildContext context) {
    if (resume.education.isEmpty) {
      return _buildEmptyHint(context, AppStrings.sdmCvNoData);
    }
    return Column(
      children: resume.education.map((e) => _buildEducationItem(context, e)).toList(),
    );
  }

  Widget _buildEducationItem(
    BuildContext context,
    SdmEducationEntity edu,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.school,
                size: AppDimensions.iconMd,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    edu.institution,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    '${edu.degree} — ${edu.field}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Row(
                    children: [
                      Text(
                        edu.isCurrent
                            ? '${edu.startYear} — Sekarang'
                            : '${edu.startYear} — ${edu.endYear ?? '-'}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textHint,
                            ),
                      ),
                      if (edu.gpa != null) ...[
                        const SizedBox(width: AppDimensions.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppDimensions.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.successSurface,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusSm),
                          ),
                          child: Text(
                            'GPA ${edu.gpa!.toStringAsFixed(2)}',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildWorkList(BuildContext context) {
    if (resume.workExperience.isEmpty) {
      return _buildEmptyHint(context, AppStrings.sdmCvNoData);
    }
    return Column(
      children: resume.workExperience
          .map((e) => _buildWorkItem(context, e))
          .toList(),
    );
  }

  Widget _buildWorkItem(
    BuildContext context,
    SdmWorkExperienceEntity work,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.secondaryLight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.work,
                size: AppDimensions.iconMd,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(width: AppDimensions.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    work.position,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    work.company,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  Text(
                    work.isCurrent
                        ? '${_fmtDate(work.startDate)} — Sekarang'
                        : '${_fmtDate(work.startDate)} — ${work.endDate != null ? _fmtDate(work.endDate!) : '-'}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textHint,
                        ),
                  ),
                  if (work.description != null) ...[
                    const SizedBox(height: AppDimensions.xs),
                    Text(
                      work.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildSkillsWrap(BuildContext context) {
    if (resume.skills.isEmpty) {
      return _buildEmptyHint(context, AppStrings.sdmCvNoData);
    }
    return Wrap(
      spacing: AppDimensions.sm,
      runSpacing: AppDimensions.sm,
      children: resume.skills.map((s) => _buildSkillChip(context, s)).toList(),
    );
  }

  Widget _buildSkillChip(BuildContext context, String skill) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusCircle),
          border: Border.all(color: AppColors.primaryLight.withOpacity(0.3)),
        ),
        child: Text(
          skill,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
        ),
      );

  Widget _buildCertificationList(BuildContext context) => Column(
        children: resume.certifications
            .map((c) => _buildCertItem(context, c))
            .toList(),
      );

  Widget _buildCertItem(
    BuildContext context,
    SdmCertificationEntity cert,
  ) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.sm),
        child: Row(
          children: [
            const Icon(
              Icons.verified,
              size: AppDimensions.iconMd,
              color: AppColors.success,
            ),
            const SizedBox(width: AppDimensions.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cert.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  Text(
                    '${cert.issuer} · ${_fmtDate(cert.issuedDate)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _buildLanguageList(BuildContext context) => Wrap(
        spacing: AppDimensions.sm,
        runSpacing: AppDimensions.sm,
        children: resume.languages
            .map((l) => _buildLanguageChip(context, l))
            .toList(),
      );

  Widget _buildLanguageChip(
    BuildContext context,
    SdmLanguageEntity lang,
  ) =>
      Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.sm,
          vertical: AppDimensions.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              lang.language,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(width: AppDimensions.xs),
            Text(
              '· ${lang.proficiency}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      );

  Widget _buildEmptyHint(BuildContext context, String text) => Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
      );

  String _fmtDate(DateTime d) => '${_monthName(d.month)} ${d.year}';

  String _monthName(int m) => const [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des'
      ][m];
}

class _LinkItem {
  final IconData icon;
  final String label;
  final String url;

  const _LinkItem(this.icon, this.label, this.url);
}
