part of '../book_material.dart';

Widget _buildHorizontalMetaItem(
  BuildContext context,
  String label,
  String value, {
  bool isCode = false,
}) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: tt.bodySmall?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value.isNotEmpty ? value : '--',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: tt.bodyMedium?.copyWith(
          fontFamily: isCode ? 'monospace' : null,
          fontWeight: isCode ? FontWeight.bold : FontWeight.w600,
          color: cs.onSurface,
        ),
      ),
    ],
  );
}

Widget _buildVerticalDivider(ColorScheme cs) {
  return Container(
    height: 28,
    width: 1,
    color: cs.outlineVariant.withValues(alpha: 0.5),
    margin: const EdgeInsets.symmetric(horizontal: 8),
  );
}

Widget buildMaterialHoldings(
  BuildContext context,
  BookInfo book,
  DesignStyle ds,
) {
  final cs = Theme.of(context).colorScheme;
  final tt = Theme.of(context).textTheme;

  return FutureBuilder<BookDetail>(
    future: fetchBookLocations(detailUrl: book.detailUrl),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Column(
          children: [
            const SizedBox(height: 8),
            const LinearProgressIndicatorM3E(),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '正在获取实时馆藏位置...',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
          ],
        );
      }

      if (snapshot.hasError) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(AppIcons.errorOutline(ds), color: cs.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '获取详细馆藏失败，请重试。',
                  style: tt.bodyMedium?.copyWith(color: cs.onErrorContainer),
                ),
              ),
            ],
          ),
        );
      }

      final detail = snapshot.data;
      if (detail == null) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '未能获取到书籍详细信息。',
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        );
      }

      final locations = detail.locations;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3-column Metadata Dashboard Card
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildHorizontalMetaItem(
                    context,
                    'ISBN',
                    detail.isbn,
                    isCode: true,
                  ),
                ),
                _buildVerticalDivider(cs),
                Expanded(
                  child: _buildHorizontalMetaItem(context, '定价', detail.price),
                ),
                _buildVerticalDivider(cs),
                Expanded(
                  child: _buildHorizontalMetaItem(context, '页数', detail.pages),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(AppIcons.place(ds), size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                '具体馆藏分布与借阅状态',
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (locations.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '暂无具体馆藏地点记录。',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            )
          else
            ...locations.map((loc) {
              final isAvailable =
                  loc.status.contains('在架') ||
                  loc.status.contains('可借') ||
                  loc.status.contains('在馆');
              final statusBgColor = isAvailable
                  ? Colors.green.shade50
                  : Colors.red.shade50;
              final statusTextColor = isAvailable
                  ? Colors.green.shade700
                  : Colors.red.shade700;
              final statusIcon = isAvailable
                  ? Icons.check_circle_outline
                  : Icons.remove_circle_outline;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.place(ds),
                      color: cs.primary.withValues(alpha: 0.7),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        loc.location,
                        style: tt.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusTextColor.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusTextColor),
                          const SizedBox(width: 4),
                          Text(
                            loc.status,
                            style: tt.labelSmall?.copyWith(
                              color: statusTextColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    },
  );
}
