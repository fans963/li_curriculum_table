import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter/services.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/glass_card.dart';
import 'package:li_curriculum_table/core/presentation/glass_dialog.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/book/domain/book_cover_loader.dart';
import 'package:signals/signals_flutter.dart';

part 'widgets/cupertino_book_card.dart';
part 'widgets/cupertino_book_detail_dialog.dart';
part 'widgets/cupertino_book_holdings.dart';
// ═══════════════════════════════════════════════════════════════════════════
// Cupertino Book Page — Waterfall grid with cover images
// ═══════════════════════════════════════════════════════════════════════════

Widget buildBookCupertino(
  BuildContext context, {
  required TextEditingController searchController,
  required VoidCallback onSearch,
  required bool isLoading,
  required bool hasSearched,
  required String? error,
  required List<BookInfo> books,
  required void Function(BookInfo book) onBookTap,
}) {
  return GlassScaffold(
    title: '图书搜寻',
    slivers: [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: CupertinoSearchTextField(
            controller: searchController,
            placeholder: '输入书名检索馆藏',
            onSubmitted: (_) => onSearch(),
          ),
        ),
      ),
      _buildCupertinoContent(
        context,
        isLoading: isLoading,
        hasSearched: hasSearched,
        error: error,
        books: books,
        onSearch: onSearch,
        onBookTap: onBookTap,
      ),
    ],
  );
}

Widget _buildCupertinoContent(
  BuildContext context, {
  required bool isLoading,
  required bool hasSearched,
  required String? error,
  required List<BookInfo> books,
  required VoidCallback onSearch,
  required void Function(BookInfo book) onBookTap,
}) {
  if (isLoading) {
    return const SliverFillRemaining(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CupertinoActivityIndicator(),
          SizedBox(height: 16),
          Text('正在检索南理工馆藏图书...'),
        ]),
      ),
    );
  }

  if (error != null) {
    return SliverFillRemaining(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.wifi_slash, size: 64, color: CupertinoColors.systemRed.resolveFrom(context)),
          const SizedBox(height: 16),
          const Text('出现错误', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(error, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          const SizedBox(height: 24),
          CupertinoButton.filled(onPressed: onSearch, child: const Text('重新尝试')),
        ]),
      ),
    );
  }

  if (!hasSearched) {
    return SliverFillRemaining(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(shape: BoxShape.circle, color: CupertinoColors.systemFill.resolveFrom(context)),
            child: Icon(CupertinoIcons.collections, size: 72, color: CupertinoColors.systemBlue.resolveFrom(context)),
          ),
          const SizedBox(height: 24),
          const Text('南理工图书搜寻', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('输入您想查找的书名，即刻查询图书馆馆藏',
              style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        ]),
      ),
    );
  }

  if (books.isEmpty) {
    return SliverFillRemaining(
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(CupertinoIcons.search, size: 64, color: CupertinoColors.systemGrey.resolveFrom(context)),
          const SizedBox(height: 16),
          const Text('未找到相关书籍', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('换个简短的关键词再试试', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        ]),
      ),
    );
  }

  // Waterfall grid
  final leftBooks = <BookInfo>[];
  final rightBooks = <BookInfo>[];
  for (var i = 0; i < books.length; i++) {
    (i.isEven ? leftBooks : rightBooks).add(books[i]);
  }

  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (final book in leftBooks)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 0, 6, 12),
                    child: _CupertinoBookCard(book: book, onTap: () => onBookTap(book)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                for (final book in rightBooks)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 0, 0, 12),
                    child: _CupertinoBookCard(book: book, onTap: () => onBookTap(book)),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
