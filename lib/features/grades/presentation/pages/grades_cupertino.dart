import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show Colors;
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import '../../domain/models/grade.dart';
import 'package:collection/collection.dart';
import 'package:li_curriculum_table/util/util.dart';

Widget buildGradesCupertino(BuildContext context, GradeState state) {
  return GlassScaffold(
    title: '成绩查询',
    slivers: [
      SliverToBoxAdapter(child: _buildCupertinoSummary(context, state)),
      if (state.isLoading && state.grades.isEmpty)
        const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()),
        )
      else if (state.needsLogin)
        SliverFillRemaining(child: _buildCupertinoNeedsLogin(context))
      else if (state.grades.isEmpty)
        const SliverFillRemaining(child: Center(child: Text('暂无成绩记录')))
      else
        _buildCupertinoGradeList(context, state),
    ],
  );
}

// ── Summary Card ──

Widget _buildCupertinoSummary(BuildContext context, GradeState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context)
            .withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              context,
              '选中加权均分',
              state.selectedWeightedAverage.toStringAsFixed(2),
              '${state.selectedCredits.toStringAsFixed(1)} 学分',
            ),
          ),
          Container(
            width: 0.5,
            height: 40,
            color: CupertinoColors.separator
                .resolveFrom(context)
                .withValues(alpha: 0.4),
          ),
          Expanded(
            child: _statItem(
              context,
              '总加权均分',
              state.weightedAverage.toStringAsFixed(2),
              '${state.totalCredits.toStringAsFixed(1)} 学分',
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _statItem(BuildContext context, String label, String value, String sub) {
  return Column(
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      Text(
        sub,
        style: TextStyle(
          fontSize: 12,
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
      ),
    ],
  );
}

// ── Grade List ──

Widget _buildCupertinoGradeList(BuildContext context, GradeState state) {
  final grouped = groupBy(state.filteredGrades, (GradeEntity g) => g.term);
  final terms = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final controller = sl<GradeController>();
  final allCount = state.grades.length;
  final selectedCount = state.selectedCourseCodes.length;

  return SliverList(
    delegate: SliverChildListDelegate([
      // Search field
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: CupertinoSearchTextField(
          placeholder: '搜索课程名称...',
          onChanged: (val) => controller.setSearchQuery(val),
        ),
      ),
      // Preset chips
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Row(
          children: [
            _buildCupertinoPresetButton(
              context,
              label: '必修',
              isSelected: _isCompulsorySelected(state),
              onTap: () => controller.selectCompulsory(),
            ),
            const SizedBox(width: 8),
            _buildCupertinoPresetButton(
              context,
              label: '全部',
              isSelected: selectedCount == allCount,
              onTap: () => controller.selectAll(),
            ),
            const Spacer(),
            Text(
              '已选 $selectedCount/$allCount 门',
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
          ],
        ),
      ),
      // Grade cards per term
      ...terms.map((term) {
        final termGrades = grouped[term]!;
        double termTotalCredits = 0,
            termWeightedSum = 0,
            termCompulsoryCredits = 0,
            termCompulsoryWeightedSum = 0;
        for (var g in termGrades) {
          if (g.credits > 0) {
            termTotalCredits += g.credits;
            termWeightedSum += g.numericScore * g.credits;
            if (g.courseAttribute.contains('必修')) {
              termCompulsoryCredits += g.credits;
              termCompulsoryWeightedSum += g.numericScore * g.credits;
            }
          }
        }
        final termWavg = termTotalCredits > 0
            ? termWeightedSum / termTotalCredits
            : 0.0;
        final termCompWavg = termCompulsoryCredits > 0
            ? termCompulsoryWeightedSum / termCompulsoryCredits
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue
                          .resolveFrom(context)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      term,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.systemBlue.resolveFrom(context),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '必修均分 ${termCompWavg.toStringAsFixed(2)} · 本期均分 ${termWavg.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(
                        context,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ...termGrades.map(
              (grade) => _buildCupertinoGradeCard(context, grade, state),
            ),
            const SizedBox(height: 8),
          ],
        );
      }),
      const SizedBox(height: 40),
    ]),
  );
}

Widget _buildCupertinoGradeCard(
  BuildContext context,
  GradeEntity grade,
  GradeState state,
) {
  final score = grade.numericScore;
  final isSelected = state.selectedCourseCodes.contains(grade.courseCode);
  final controller = sl<GradeController>();

  CupertinoDynamicColor scoreColor;
  if (score >= 90) {
    scoreColor = CupertinoColors.systemGreen;
  } else if (score >= 80) {
    scoreColor = CupertinoColors.systemBlue;
  } else if (score >= 70) {
    scoreColor = CupertinoColors.systemOrange;
  } else if (score >= 60) {
    scoreColor = CupertinoColors.systemTeal;
  } else {
    scoreColor = CupertinoColors.systemRed;
  }

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    child: GestureDetector(
      onTap: () => controller.toggleCourseSelection(grade.courseCode),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? CupertinoColors.systemBlue
                    .resolveFrom(context)
                    .withValues(alpha: 0.08)
              : CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
                  context,
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              AnimatedContainer(
                duration: kDefaultAnimationDuration,
                curve: kSpringCurve,
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? CupertinoColors.activeBlue
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? CupertinoColors.activeBlue
                        : CupertinoColors.systemGrey,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        CupertinoIcons.check_mark,
                        size: 14,
                        color: CupertinoColors.white,
                      )
                    : null,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      grade.courseName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${grade.credits} 学分 · ${grade.courseAttribute}',
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: scoreColor.resolveFrom(context).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    Text(
                      grade.score,
                      style: TextStyle(
                        color: scoreColor.resolveFrom(context),
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      'GRADE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: scoreColor
                            .resolveFrom(context)
                            .withValues(alpha: 0.6),
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
  );
}

// ── Helpers ──

bool _isCompulsorySelected(GradeState state) {
  final compulsory = state.grades
      .where((g) => g.courseAttribute.contains('必修'))
      .map((g) => g.courseCode)
      .toSet();
  return state.selectedCourseCodes.containsAll(compulsory) &&
      state.selectedCourseCodes.length == compulsory.length;
}

Widget _buildCupertinoPresetButton(
  BuildContext context, {
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: kInteractionDuration,
      curve: kEmphasizedCurve,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isSelected
            ? CupertinoColors.activeBlue
            : CupertinoColors.systemGrey5.resolveFrom(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? CupertinoColors.white
              : CupertinoColors.label.resolveFrom(context),
        ),
      ),
    ),
  );
}

Widget _buildCupertinoNeedsLogin(BuildContext context) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          CupertinoIcons.lock,
          size: 64,
          color: CupertinoColors.systemGrey.resolveFrom(context),
        ),
        const SizedBox(height: 16),
        const Text(
          '需要登录后才能查询成绩',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          '请先前往「设置」页面输入账号密码',
          style: TextStyle(
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    ),
  );
}
