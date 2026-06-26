import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:li_curriculum_table/core/presentation/glass_dialog.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
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
  // Advanced search
  required String advSearchType,
  required String advDoctype,
  required String advDept,
  required String advSort,
  required String advOrderby,
  required int advDisplaypg,
  required List<String> searchTypeLabels,
  required List<String> doctypeLabels,
  required List<String> deptLabels,
  required List<String> sortLabels,
  required List<int> displaypgOptions,
  required Map<String, String> searchTypeMap,
  required Map<String, String> doctypeMap,
  required Map<String, String> deptMap,
  required Map<String, String> sortMap,
  required Map<String, void Function(String)> onAdvChanged,
  // Pagination
  required int page,
  required int totalCount,
  required int totalPages,
  required void Function(int) onPageChanged,
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
      // Advanced search panel (Cupertino)
      SliverToBoxAdapter(
        child: _CupertinoAdvSearchPanel(
          advSearchType: advSearchType,
          advDoctype: advDoctype,
          advDept: advDept,
          advSort: advSort,
          advOrderby: advOrderby,
          advDisplaypg: advDisplaypg,
          searchTypeLabels: searchTypeLabels,
          doctypeLabels: doctypeLabels,
          deptLabels: deptLabels,
          sortLabels: sortLabels,
          displaypgOptions: displaypgOptions,
          searchTypeMap: searchTypeMap,
          doctypeMap: doctypeMap,
          deptMap: deptMap,
          sortMap: sortMap,
          onAdvChanged: onAdvChanged,
        ),
      ),
      // Cupertino pagination bar
      if (hasSearched && totalCount > 0)
        SliverToBoxAdapter(
          child: _CupertinoPaginationBar(
            page: page,
            totalCount: totalCount,
            totalPages: totalPages,
            onPageChanged: onPageChanged,
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
// Cupertino Advanced Search Panel
// ═══════════════════════════════════════════════════════════════════════════

class _CupertinoAdvSearchPanel extends SignalStatefulWidget {
  final String advSearchType, advDoctype, advDept, advSort, advOrderby;
  final int advDisplaypg;
  final List<String> searchTypeLabels, doctypeLabels, deptLabels, sortLabels;
  final List<int> displaypgOptions;
  final Map<String, String> searchTypeMap, doctypeMap, deptMap, sortMap;
  final Map<String, void Function(String)> onAdvChanged;

  const _CupertinoAdvSearchPanel({
    required this.advSearchType,
    required this.advDoctype,
    required this.advDept,
    required this.advSort,
    required this.advOrderby,
    required this.advDisplaypg,
    required this.searchTypeLabels,
    required this.doctypeLabels,
    required this.deptLabels,
    required this.sortLabels,
    required this.displaypgOptions,
    required this.searchTypeMap,
    required this.doctypeMap,
    required this.deptMap,
    required this.sortMap,
    required this.onAdvChanged,
  });

  @override
  State<_CupertinoAdvSearchPanel> createState() =>
      _CupertinoAdvSearchPanelState();
}

class _CupertinoAdvSearchPanelState extends State<_CupertinoAdvSearchPanel> {
  final _expanded = signal(false);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _expanded.value = !_expanded.value,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Icon(CupertinoIcons.slider_horizontal_3, size: 16,
                      color: CupertinoColors.secondaryLabel.resolveFrom(context)),
                  const SizedBox(width: 6),
                  Text('高级检索',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500,
                          color: CupertinoColors.secondaryLabel.resolveFrom(context))),
                  const Spacer(),
                  Icon(_expanded.value ? CupertinoIcons.chevron_up : CupertinoIcons.chevron_down,
                      size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
                ],
              ),
            ),
          ),
          if (_expanded.value)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3)),
              ),
              child: Column(children: [
                _cupertinoAdvRow(context, '检索字段', widget.advSearchType,
                    widget.searchTypeLabels, widget.searchTypeMap, widget.onAdvChanged['searchType']!),
                const _CupertinoAdvDivider(),
                _cupertinoAdvRow(context, '文献类型', widget.advDoctype,
                    widget.doctypeLabels, widget.doctypeMap, widget.onAdvChanged['doctype']!),
                const _CupertinoAdvDivider(),
                _cupertinoAdvRow(context, '校区', widget.advDept,
                    widget.deptLabels, widget.deptMap, widget.onAdvChanged['dept']!),
                const _CupertinoAdvDivider(),
                _cupertinoAdvRow(context, '排序', widget.advSort,
                    widget.sortLabels, widget.sortMap, widget.onAdvChanged['sort']!),
                const _CupertinoAdvDivider(),
                _cupertinoAdvRow(context, '方向', widget.advOrderby,
                    ['DESC', 'asc'], {'DESC': '最新优先', 'asc': '最早优先'},
                    widget.onAdvChanged['orderby']!),
                const _CupertinoAdvDivider(),
                _cupertinoAdvRow(context, '每页', '${widget.advDisplaypg}',
                    widget.displaypgOptions.map((n) => '$n').toList(),
                    Map.fromEntries(widget.displaypgOptions.map((n) => MapEntry('$n', '$n 条'))),
                    widget.onAdvChanged['displaypg']!),
              ]),
            ),
        ],
      ),
    );
  }
}

Widget _cupertinoAdvRow(
  BuildContext context,
  String label,
  String value,
  List<String> items,
  Map<String, String> labels,
  void Function(String) onChanged,
) {
  return GestureDetector(
    onTap: () {
      showCupertinoModalPopup(
        context: context,
        builder: (ctx) => CupertinoActionSheet(
          title: Text(label),
          actions: items.map((item) {
            final sel = item == value;
            return CupertinoActionSheetAction(
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(labels[item] ?? item),
                if (sel) ...[const SizedBox(width: 8), const Icon(CupertinoIcons.check_mark, size: 18, color: CupertinoColors.activeBlue)],
              ]),
              onPressed: () { onChanged(item); Navigator.pop(ctx); },
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(isDefaultAction: true, child: const Text('取消'), onPressed: () => Navigator.pop(ctx)),
        ),
      );
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 14))),
        Text(labels[value] ?? value,
            style: TextStyle(fontSize: 14, color: CupertinoColors.secondaryLabel.resolveFrom(context))),
        const SizedBox(width: 4),
        Icon(CupertinoIcons.chevron_forward, size: 14, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
      ]),
    ),
  );
}

class _CupertinoAdvDivider extends StatelessWidget {
  const _CupertinoAdvDivider();
  @override
  Widget build(BuildContext context) =>
      Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3));
}

// ═══════════════════════════════════════════════════════════════════════════
// Cupertino Pagination Bar
// ═══════════════════════════════════════════════════════════════════════════

class _CupertinoPaginationBar extends StatelessWidget {
  final int page, totalCount, totalPages;
  final void Function(int) onPageChanged;
  const _CupertinoPaginationBar({
    required this.page, required this.totalCount, required this.totalPages, required this.onPageChanged,
  });
  @override
  Widget build(BuildContext context) {
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          minimumSize: Size.zero,
          child: Text('上一页', style: TextStyle(fontSize: 14, color: page > 1 ? CupertinoColors.systemBlue.resolveFrom(context) : secondary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('$page / $totalPages ($totalCount 条)', style: TextStyle(fontSize: 13, color: secondary)),
        ),
        CupertinoButton(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          minimumSize: Size.zero,
          child: Text('下一页', style: TextStyle(fontSize: 14, color: page < totalPages ? CupertinoColors.systemBlue.resolveFrom(context) : secondary)),
        ),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
