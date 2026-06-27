import 'package:flutter/material.dart';
import 'package:li_curriculum_table/features/level_exam_scores/domain/models/level_exam_score.dart';

class LevelExamScoresSection extends StatelessWidget {
  final List<LevelExamScoreEntity> scores;
  const LevelExamScoresSection({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '等级考试',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text('${scores.length} 项', style: theme.textTheme.bodySmall),
            ],
          ),
        ),
        ...scores.map((s) => _LevelExamScoreCard(score: s)),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _LevelExamScoreCard extends StatelessWidget {
  final LevelExamScoreEntity score;
  const _LevelExamScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      score.courseName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (score.writtenScore.isNotEmpty &&
                            score.writtenScore != '0')
                          _buildTag(
                            context,
                            '笔试 ${score.writtenScore}',
                            cs.surfaceContainerHighest,
                            cs.onSurfaceVariant,
                          ),
                        if (score.practicalScore.isNotEmpty &&
                            score.practicalScore != '0')
                          _buildTag(
                            context,
                            '机试 ${score.practicalScore}',
                            cs.surfaceContainerHighest,
                            cs.onSurfaceVariant,
                          ),
                        if (score.writtenGrade.isNotEmpty)
                          _buildTag(
                            context,
                            score.writtenGrade,
                            cs.tertiaryContainer,
                            cs.tertiary,
                          ),
                        if (score.practicalGrade.isNotEmpty)
                          _buildTag(
                            context,
                            score.practicalGrade,
                            cs.tertiaryContainer,
                            cs.tertiary,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    constraints: const BoxConstraints(minWidth: 64),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cs.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          score.displayScore,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          'TOTAL',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.primary.withValues(alpha: 0.6),
                            fontWeight: FontWeight.bold,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (score.examDate.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      score.examDate,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.outline,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(
    BuildContext context,
    String text,
    Color bgColor,
    Color fgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: fgColor, fontSize: 11),
      ),
    );
  }
}
