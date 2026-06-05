import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import '../../domain/models/grade.dart';
import 'package:collection/collection.dart';
import 'package:signals/signals_flutter.dart';
import 'grades_cupertino.dart';

class GradesTab extends StatefulWidget {
  const GradesTab({super.key});

  @override
  State<GradesTab> createState() => _GradesTabState();
}

class _GradesTabState extends State<GradesTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SignalBuilder(builder: (context) {
      final state = sl<GradeController>().state.value;
      final isCupertino = AdaptiveStyle.isCupertino(
        sl<SettingsController>().designStyle.value,
      );

      if (isCupertino) {
        return buildGradesCupertino(context, state);
      }
      return _buildMaterial(context, state);
    });
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context, GradeState state) {
    return Scaffold(
      appBar: _buildHeader(context, state),
      body: _buildBody(context, state),
    );
  }

  PreferredSizeWidget _buildHeader(
      BuildContext context, GradeState state) {
    return AppBar(
      title: const Text('成绩查询'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSummaryCard(context, state),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      BuildContext context, GradeState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ds = sl<SettingsController>().designStyle.value;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.05),
            colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                '选中加权均分',
                state.selectedWeightedAverage.toStringAsFixed(2),
                AppIcons.stars(ds),
                '${state.selectedCredits.toStringAsFixed(1)} 学分',
                colorScheme.primary,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                '总加权均分',
                state.weightedAverage.toStringAsFixed(2),
                AppIcons.analytics(ds),
                '${state.totalCredits.toStringAsFixed(1)} 总学分',
                colorScheme.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    String subValue,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        ),
        Text(
          subValue,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, GradeState state) {
    return AnimatedSwitcher(
      duration: kDefaultAnimationDuration,
      switchInCurve: kDefaultAnimationCurve,
      switchOutCurve: kDefaultAnimationCurve,
      child: () {
        if (state.isLoading && state.grades.isEmpty) {
          return const Center(
              key: ValueKey('loading'),
              child: CircularProgressIndicator());
        }

        if (state.needsLogin) {
          final ds = sl<SettingsController>().designStyle.value;
          return Center(
            key: const ValueKey('needs_login'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.lock(ds),
                    size: 64,
                    color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('需要登录后才能查询成绩'),
                const SizedBox(height: 8),
                Text(
                  '请先前往「设置」页面输入账号密码',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color:
                            Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        if (state.grades.isEmpty) {
          return const Center(
              key: ValueKey('empty'), child: Text('暂无成绩记录'));
        }

        final grouped = groupBy(
            state.filteredGrades, (GradeEntity g) => g.term);
        final terms = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Column(
          key: const ValueKey('grades_list'),
          children: [
            _buildSearchField(context, state),
            Expanded(
              child: ListView.builder(
                itemCount: terms.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final term = terms[index];
                  final termGrades = grouped[term]!;
                  return _buildTermSection(context, term, termGrades, state);
                },
              ),
            ),
          ],
        );
      }(),
    );
  }

  Widget _buildSearchField(BuildContext context, GradeState state) {
    final ds = sl<SettingsController>().designStyle.value;
    final controller = sl<GradeController>();
    final allCount = state.grades.length;
    final selectedCount = state.selectedCourseCodes.length;
    final isAllSelected = selectedCount == allCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: '搜索课程名称...',
              prefixIcon: Icon(AppIcons.search(ds)),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onChanged: (val) => controller.setSearchQuery(val),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildPresetChip(
                context,
                label: '必修',
                isSelected: _isCompulsorySelected(state),
                onTap: () => controller.selectCompulsory(),
              ),
              const SizedBox(width: 8),
              _buildPresetChip(
                context,
                label: '全部',
                isSelected: isAllSelected,
                onTap: () => controller.selectAll(),
              ),
              const Spacer(),
              Text(
                '已选 $selectedCount/$allCount 门',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isCompulsorySelected(GradeState state) {
    final compulsory = state.grades
        .where((g) => g.courseAttribute.contains('必修'))
        .map((g) => g.courseCode)
        .toSet();
    return state.selectedCourseCodes.containsAll(compulsory) &&
        state.selectedCourseCodes.length == compulsory.length;
  }

  Widget _buildPresetChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.3)
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ),
    );
  }

  Widget _buildTermSection(
      BuildContext context, String term, List<GradeEntity> grades,
      GradeState state) {
    final theme = Theme.of(context);

    double termTotalCredits = 0;
    double termWeightedSum = 0;
    double termCompulsoryCredits = 0;
    double termCompulsoryWeightedSum = 0;

    for (var grade in grades) {
      if (grade.credits > 0) {
        termTotalCredits += grade.credits;
        termWeightedSum += grade.numericScore * grade.credits;

        if (grade.courseAttribute.contains('必修')) {
          termCompulsoryCredits += grade.credits;
          termCompulsoryWeightedSum +=
              grade.numericScore * grade.credits;
        }
      }
    }

    final double termWavg =
        termTotalCredits > 0 ? termWeightedSum / termTotalCredits : 0.0;
    final double termCompWavg = termCompulsoryCredits > 0
        ? termCompulsoryWeightedSum / termCompulsoryCredits
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      term,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${grades.length} 门课',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildMiniStat(context, '必修均分',
                      termCompWavg.toStringAsFixed(2)),
                  const SizedBox(width: 16),
                  _buildMiniStat(context, '本期均分',
                      termWavg.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
        ...grades.map((g) => _buildGradeCard(context, g, state)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMiniStat(
      BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.outline),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildGradeCard(
      BuildContext context, GradeEntity grade, GradeState state) {
    final isSelected = state.selectedCourseCodes.contains(grade.courseCode);
    return _GradeItemCard(
      grade: grade,
      isSelected: isSelected,
      onToggle: () => sl<GradeController>().toggleCourseSelection(grade.courseCode),
    );
  }
}

class _GradeItemCard extends StatefulWidget {
  final GradeEntity grade;
  final bool isSelected;
  final VoidCallback onToggle;
  const _GradeItemCard({
    required this.grade,
    required this.isSelected,
    required this.onToggle,
  });

  @override
  State<_GradeItemCard> createState() => _GradeItemCardState();
}

class _GradeItemCardState extends State<_GradeItemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final grade = widget.grade;
    final score = grade.numericScore;
    final ds = sl<SettingsController>().designStyle.value;
    final isSelected = widget.isSelected;

    Color scoreColor;
    if (score >= 90) {
      scoreColor = colorScheme.tertiary;
    } else if (score >= 80) {
      scoreColor = colorScheme.primary;
    } else if (score >= 70) {
      scoreColor = colorScheme.secondary;
    } else if (score >= 60) {
      scoreColor = colorScheme.onSurfaceVariant;
    } else {
      scoreColor = colorScheme.error;
    }

    return Center(
      child: AnimatedScale(
        scale: _isPressed ? 0.97 : 1.0,
        duration: kInteractionDuration,
        curve: kEmphasizedCurve,
        child: AnimatedContainer(
          duration: kDefaultAnimationDuration,
          curve: kDefaultAnimationCurve,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withValues(alpha: 0.35)
                : colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(isSelected ? 20 : 16),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.4)
                  : colorScheme.outlineVariant.withValues(alpha: 0.5),
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: [
              if (!_isPressed)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: InkWell(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Selection indicator — M3 Expressive spring animation
                  AnimatedContainer(
                    duration: kDefaultAnimationDuration,
                    curve: kSpringCurve,
                    width: 24,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? Icon(Icons.check, size: 16, color: colorScheme.onPrimary)
                        : null,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          grade.courseName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _buildChip(context, '${grade.credits} 学分',
                                AppIcons.starOutline(ds)),
                            _buildChip(context, grade.courseAttribute,
                                AppIcons.bookmark(ds)),
                            _buildChip(context, grade.courseNature,
                                AppIcons.category(ds)),
                            if (grade.scoreMark.isNotEmpty)
                              _buildChip(context, grade.scoreMark,
                                  AppIcons.info(ds)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(minWidth: 64),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: scoreColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          grade.score,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: scoreColor,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'GRADE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: scoreColor.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
      BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: theme.colorScheme.outline),
          const SizedBox(width: 4),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
