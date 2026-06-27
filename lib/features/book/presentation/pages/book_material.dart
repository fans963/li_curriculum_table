import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator_m3e/loading_indicator_m3e.dart';
import 'package:m3e_core/m3e_core.dart';
import 'package:progress_indicator_m3e/progress_indicator_m3e.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/domain/book_cover_loader.dart';
import 'package:li_curriculum_table/core/presentation/info_row.dart';
import 'package:signals/signals_flutter.dart';

part 'widgets/material_book_card.dart';
part 'widgets/material_book_holdings.dart';

Widget buildMaterialBody(
  BuildContext context, {
  required DesignStyle ds,
  required bool isLoading,
  required String? error,
  required bool hasSearched,
  required List<BookInfo> books,
  required VoidCallback onRetry,
  required void Function(BookInfo book, Offset cardCenter, Size cardSize)
  onBookTap,
}) {
  final colorScheme = Theme.of(context).colorScheme;
  final textTheme = Theme.of(context).textTheme;

  if (isLoading) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LoadingIndicatorM3E(),
          const SizedBox(height: 16),
          Text(
            '正在为您检索南理工馆藏图书...',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  if (error != null) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.cloudOff(ds), size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              '出现错误',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            M3EFilledButton.icon(
              icon: Icon(AppIcons.refresh(ds), size: 18),
              label: const Text('重新尝试'),
              size: M3EButtonSize.md,
              shape: M3EButtonShape.round,
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }

  if (!hasSearched) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primaryContainer.withValues(alpha: 0.2),
              ),
              child: Icon(
                AppIcons.libraryBooks(ds),
                size: 72,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '南理工图书搜寻',
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '输入您想查找的书名，即刻查询南京理工大学图书馆\n的文献种类、索书号以及具体的实时馆藏位置。',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  if (books.isEmpty) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(AppIcons.searchOff(ds), size: 64, color: colorScheme.outline),
            const SizedBox(height: 16),
            Text(
              '未找到相关书籍',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '换个简短的关键词或者书名再试试吧~',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return _BookWaterfallGrid(books: books, ds: ds, onBookTap: onBookTap);
}
