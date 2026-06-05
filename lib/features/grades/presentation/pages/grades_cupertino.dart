import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_controller.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import '../../domain/models/grade.dart';
import 'package:collection/collection.dart';
import 'package:li_curriculum_table/util/util.dart';

Widget buildGradesCupertino(BuildContext context, GradeState state) {
  final topPadding = MediaQuery.of(context).padding.top;
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Stack(
      children: [
        // Scroll content with background
        Positioned.fill(
          child: ColoredBox(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            child: CustomScrollView(
              slivers: [
                // Spacer for nav bar height
                SliverToBoxAdapter(
                  child: SizedBox(height: topPadding + 44),
                ),
                SliverToBoxAdapter(
                  child: _buildCupertinoSummary(context, state),
                ),
                if (state.isLoading && state.grades.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CupertinoActivityIndicator()),
                  )
                else if (state.needsLogin)
                  SliverFillRemaining(
                    child: _buildCupertinoNeedsLogin(context),
                  )
                else if (state.grades.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: Text('暂无成绩记录')),
                  )
                else
                  _buildCupertinoGradeList(context, state),
              ],
            ),
          ),
        ),
        // Floating Liquid Glass nav bar
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
          child: CupertinoLiquidGlass(
            tintOpacity: 0.15,
            child: Padding(
              padding: EdgeInsets.only(
                top: topPadding,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: 44,
                child: Stack(
                  children: [
                    const Center(
                      child: Text(
                        '成绩查询',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.41,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCupertinoSummary(BuildContext context, GradeState state) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: CupertinoColors.secondarySystemGroupedBackground
            .resolveFrom(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  '选中加权均分',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.selectedWeightedAverage.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${state.selectedCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 0.5,
            height: 40,
            color: CupertinoColors.separator.resolveFrom(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  '总加权均分',
                  style: TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.weightedAverage.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${state.totalCredits.toStringAsFixed(1)} 学分',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          color: CupertinoColors.secondaryLabel.resolveFrom(context),
        ),
        const SizedBox(height: 16),
        const Text('需要登录后才能查询成绩'),
        const SizedBox(height: 8),
        Text(
          '请先前往「设置」页面输入账号密码',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ],
    ),
  );
}

Widget _buildCupertinoGradeList(
    BuildContext context, GradeState state) {
  final grouped =
      groupBy(state.filteredGrades, (GradeEntity g) => g.term);
  final terms = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
  final controller = sl<GradeController>();
  final allCount = state.grades.length;
  final selectedCount = state.selectedCourseCodes.length;

  return SliverList(
    delegate: SliverChildListDelegate([
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: CupertinoSearchTextField(
          placeholder: '搜索课程名称',
          onChanged: (val) => controller.setSearchQuery(val),
        ),
      ),
      // Selection preset row
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
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
      ...terms.map((term) {
        final termGrades = grouped[term]!;
        double termTotalCredits = 0;
        double termWeightedSum = 0;
        double termCompulsoryCredits = 0;
        double termCompulsoryWeightedSum = 0;
        for (var grade in termGrades) {
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
        final termWavg = termTotalCredits > 0
            ? termWeightedSum / termTotalCredits
            : 0.0;
        final termCompWavg = termCompulsoryCredits > 0
            ? termCompulsoryWeightedSum / termCompulsoryCredits
            : 0.0;

        return CupertinoListSection.insetGrouped(
          header: Text(
            term,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.08,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          footer: Text(
              '必修均分 ${termCompWavg.toStringAsFixed(2)} · 本期均分 ${termWavg.toStringAsFixed(2)}'),
          children: termGrades.map((grade) {
            final score = grade.numericScore;
            final isSelected =
                state.selectedCourseCodes.contains(grade.courseCode);
            Color scoreColor;
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

            return GestureDetector(
              onTap: () =>
                  controller.toggleCourseSelection(grade.courseCode),
              child: CupertinoListTile(
                leading: AnimatedContainer(
                  duration: kDefaultAnimationDuration,
                  curve: kSpringCurve,
                  width: 24,
                  height: 24,
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
                      ? const Icon(CupertinoIcons.check_mark,
                          size: 14, color: CupertinoColors.white)
                      : null,
                ),
                title: Text(grade.courseName),
                subtitle: Text(
                    '${grade.credits} 学分 · ${grade.courseAttribute}'),
                additionalInfo: Text(
                  grade.score,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      }),
      const SizedBox(height: 40),
    ]),
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
