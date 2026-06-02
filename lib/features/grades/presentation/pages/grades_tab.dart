import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/grades/presentation/state/grade_state.dart';
import 'package:li_curriculum_table/util/util.dart';
import '../state/grade_controller.dart';
import '../../domain/models/grade.dart';
import 'package:collection/collection.dart';

class GradesTab extends ConsumerWidget {
  const GradesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gradeControllerProvider);
    final isCupertino = AdaptiveStyle.isCupertino(
      ref.watch(settingsControllerProvider).designStyle,
    );

    if (isCupertino) {
      return _buildCupertino(context, ref, state);
    }
    return _buildMaterial(context, ref, state);
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context, WidgetRef ref, GradeState state) {
    return Scaffold(
      appBar: _buildHeader(context, ref, state),
      body: _buildBody(context, ref, state),
    );
  }

  // ─── Cupertino ─────────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context, WidgetRef ref, GradeState state) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('成绩查询'),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: null,
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
            _buildCupertinoGradeList(context, ref, state),
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
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    '必修加权均分',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    state.compulsoryWeightedAverage.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    '${state.compulsoryCredits.toStringAsFixed(1)} 学分',
                    style: TextStyle(
                      fontSize: 12,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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
                      color: CupertinoColors.secondaryLabel.resolveFrom(context),
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

  Widget _buildCupertinoGradeList(BuildContext context, WidgetRef ref, GradeState state) {
    final grouped = groupBy(state.filteredGrades, (GradeEntity g) => g.term);
    final terms = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return SliverList(
      delegate: SliverChildListDelegate([
        // Search field
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: CupertinoSearchTextField(
            placeholder: '搜索课程名称',
            onChanged: (val) => ref.read(gradeControllerProvider.notifier).setSearchQuery(val),
          ),
        ),
        // Grade sections
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
                termCompulsoryWeightedSum += grade.numericScore * grade.credits;
              }
            }
          }
          final termWavg = termTotalCredits > 0 ? termWeightedSum / termTotalCredits : 0.0;
          final termCompWavg = termCompulsoryCredits > 0 ? termCompulsoryWeightedSum / termCompulsoryCredits : 0.0;

          return CupertinoListSection.insetGrouped(
            header: Text(term),
            footer: Text('必修均分 ${termCompWavg.toStringAsFixed(2)} · 本期均分 ${termWavg.toStringAsFixed(2)}'),
            children: termGrades.map((grade) {
              final score = grade.numericScore;
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

              return CupertinoListTile(
                title: Text(grade.courseName),
                subtitle: Text('${grade.credits} 学分 · ${grade.courseAttribute}'),
                additionalInfo: Text(
                  grade.score,
                  style: TextStyle(
                    color: scoreColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 17,
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

  PreferredSizeWidget _buildHeader(BuildContext context, WidgetRef ref, GradeState state) {
    return AppBar(
      title: const Text('成绩查询'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: _buildSummaryCard(context, ref, state),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, WidgetRef ref, GradeState state) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final ds = ref.watch(settingsControllerProvider).designStyle;
    
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
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                '必修加权均分',
                state.compulsoryWeightedAverage.toStringAsFixed(2),
                AppIcons.stars(ds),
                '${state.compulsoryCredits.toStringAsFixed(1)} 必修学分',
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

  Widget _buildBody(BuildContext context, WidgetRef ref, GradeState state) {
    return AnimatedSwitcher(
      duration: kDefaultAnimationDuration,
      switchInCurve: kDefaultAnimationCurve,
      switchOutCurve: kDefaultAnimationCurve,
      child: () {
        if (state.isLoading && state.grades.isEmpty) {
          return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
        }

        if (state.needsLogin) {
          return Center(
            key: const ValueKey('needs_login'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(AppIcons.lock(ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle), size: 64, color: Theme.of(context).colorScheme.outline),
                const SizedBox(height: 16),
                const Text('需要登录后才能查询成绩'),
                const SizedBox(height: 8),
                Text(
                  '请先前往「设置」页面输入账号密码',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        if (state.grades.isEmpty) {
          return const Center(key: ValueKey('empty'), child: Text('暂无成绩记录'));
        }

        // Group grades by term
        final grouped = groupBy(state.filteredGrades, (GradeEntity g) => g.term);
        final terms = grouped.keys.toList()..sort((a, b) => b.compareTo(a)); // Newest first

        return Column(
          key: const ValueKey('grades_list'),
          children: [
            _buildSearchField(context, ref),
            Expanded(
              child: ListView.builder(
                itemCount: terms.length,
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final term = terms[index];
                  final termGrades = grouped[term]!;
                  return _buildTermSection(context, term, termGrades);
                },
              ),
            ),
          ],
        );
      }(),
    );
  }

  Widget _buildSearchField(BuildContext context, WidgetRef ref) {
    final ds = ref.watch(settingsControllerProvider).designStyle;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索课程名称...',
          prefixIcon: Icon(AppIcons.search(ds)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (val) => ref.read(gradeControllerProvider.notifier).setSearchQuery(val),
      ),
    );
  }

  Widget _buildTermSection(BuildContext context, String term, List<GradeEntity> grades) {
    final theme = Theme.of(context);
    
    // Calculate term-specific stats
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
          termCompulsoryWeightedSum += grade.numericScore * grade.credits;
        }
      }
    }

    final double termWavg = termTotalCredits > 0 ? termWeightedSum / termTotalCredits : 0.0;
    final double termCompWavg = termCompulsoryCredits > 0 ? termCompulsoryWeightedSum / termCompulsoryCredits : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                  _buildMiniStat(context, '必修均分', termCompWavg.toStringAsFixed(2)),
                  const SizedBox(width: 16),
                  _buildMiniStat(context, '本期均分', termWavg.toStringAsFixed(2)),
                ],
              ),
            ],
          ),
        ),
        ...grades.map((g) => _buildGradeCard(context, g)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMiniStat(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline),
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

  Widget _buildGradeCard(BuildContext context, GradeEntity grade) {
    return _GradeItemCard(grade: grade);
  }
}

class _GradeItemCard extends StatefulWidget {
  final GradeEntity grade;
  const _GradeItemCard({required this.grade});

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
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;
    
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
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
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
            onTap: () {}, // For splash effect
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
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
                            _buildChip(context, '${grade.credits} 学分', AppIcons.starOutline(ds)),
                            _buildChip(context, grade.courseAttribute, AppIcons.bookmark(ds)),
                            _buildChip(context, grade.courseNature, AppIcons.category(ds)),
                            if (grade.scoreMark.isNotEmpty)
                              _buildChip(context, grade.scoreMark, AppIcons.info(ds)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    constraints: const BoxConstraints(minWidth: 64),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.2)),
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

  Widget _buildChip(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
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
