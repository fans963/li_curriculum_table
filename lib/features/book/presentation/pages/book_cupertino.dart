import 'package:cupertino_liquid_glass/cupertino_liquid_glass.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:li_curriculum_table/core/rust/api/book.dart';

/// Builds the full Cupertino scaffold for the book search tab.
///
/// [onSearch] is invoked when the user submits the search field.
/// [onBookTap] is invoked when the user taps a book tile.
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
  final topPadding = MediaQuery.of(context).padding.top;
  return CupertinoPageScaffold(
    backgroundColor: Colors.transparent,
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: topPadding + 44),
                ),
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
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
          child: CupertinoLiquidGlass(
            tintOpacity: 0.15,
            child: Padding(
              padding: EdgeInsets.only(top: topPadding),
              child: const SizedBox(
                height: 44,
                child: Center(
                  child: Text(
                    '图书搜寻',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.41,
                    ),
                  ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoActivityIndicator(),
            SizedBox(height: 16),
            Text('正在检索南理工馆藏图书...'),
          ],
        ),
      ),
    );
  }

  if (error != null) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.wifi_slash, size: 64, color: CupertinoColors.systemRed.resolveFrom(context)),
            const SizedBox(height: 16),
            const Text('出现错误', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error, style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: onSearch,
              child: const Text('重新尝试'),
            ),
          ],
        ),
      ),
    );
  }

  if (!hasSearched) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemFill.resolveFrom(context),
              ),
              child: Icon(CupertinoIcons.collections, size: 72, color: CupertinoColors.systemBlue.resolveFrom(context)),
            ),
            const SizedBox(height: 24),
            const Text(
              '南理工图书搜寻',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              '输入您想查找的书名，即刻查询图书馆馆藏',
              style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          ],
        ),
      ),
    );
  }

  if (books.isEmpty) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.search, size: 64, color: CupertinoColors.systemGrey.resolveFrom(context)),
            SizedBox(height: 16),
            Text('未找到相关书籍', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            Text('换个简短的关键词再试试', style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context))),
          ],
        ),
      ),
    );
  }

  return SliverList(
    delegate: SliverChildListDelegate([
      CupertinoListSection.insetGrouped(
        children: books.map((book) {
          return CupertinoListTile(
            leading: Container(
              width: 44,
              height: 56,
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(CupertinoIcons.book, size: 22),
            ),
            title: Text(book.title, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(
              '${book.author}\n${book.publisher}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            additionalInfo: Text(
              book.callNo,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const CupertinoListTileChevron(),
            onTap: () => onBookTap(book),
          );
        }).toList(),
      ),
      const SizedBox(height: 40),
    ]),
  );
}

// ─── Cupertino Book Details Sheet ──────────────────────────────────────────

/// Shows the Cupertino-style book details bottom sheet.
void showCupertinoBookDetailsSheet(BuildContext context, BookInfo book) {
  showCupertinoModalPopup(
    context: context,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            // Drag handle
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: CupertinoColors.separator.resolveFrom(context),
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),
            // Navigation bar with close button
            CupertinoNavigationBar(
              backgroundColor: CupertinoColors.systemGroupedBackground
                  .resolveFrom(context),
              leading: const SizedBox.shrink(),
              middle: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(CupertinoIcons.xmark_circle_fill),
              ),
              border: null,
            ),
            // Scrollable content
            Expanded(
              child: _buildCupertinoDetailsContent(context, book),
            ),
          ],
        ),
      );
    },
  );
}

Widget _buildCupertinoDetailsContent(BuildContext context, BookInfo book) {
  return ListView(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    children: [
      // Title and doc type badge
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              book.title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.resolveFrom(context)
                  .withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              book.docType,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemBlue.resolveFrom(context),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
      ),
      const SizedBox(height: 16),

      // Metadata
      CupertinoListSection.insetGrouped(
        children: [
          _buildCupertinoMetaTile(
            context,
            icon: CupertinoIcons.bookmark,
            label: '索书号',
            value: book.callNo,
            isCode: true,
          ),
          _buildCupertinoMetaTile(
            context,
            icon: CupertinoIcons.person,
            label: '责任者/作者',
            value: book.author,
          ),
          _buildCupertinoMetaTile(
            context,
            icon: CupertinoIcons.building_2_fill,
            label: '出版与印刷项',
            value: book.publisher,
          ),
          _buildCupertinoMetaTile(
            context,
            icon: CupertinoIcons.archivebox,
            label: '馆藏概况',
            value: book.holdingsSummary,
          ),
        ],
      ),
      const SizedBox(height: 20),

      // Holdings section header
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          '具体馆藏分布与借阅状态',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label.resolveFrom(context),
          ),
        ),
      ),
      const SizedBox(height: 12),

      // Specific holdings list (lazy loaded)
      FutureBuilder<List<BookLocation>>(
        future: fetchBookLocations(detailUrl: book.detailUrl),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Column(
                children: [
                  const CupertinoActivityIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    '正在向南理工图书馆获取实时馆藏位置...',
                    style: TextStyle(
                      fontSize: 13,
                      color: CupertinoColors.secondaryLabel
                          .resolveFrom(context),
                    ),
                  ),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.destructiveRed
                    .resolveFrom(context)
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Icon(
                    CupertinoIcons.exclamationmark_triangle,
                    color: CupertinoColors.destructiveRed
                        .resolveFrom(context),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '获取馆藏位置失败，请重试。',
                      style: TextStyle(
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final locations = snapshot.data ?? [];
          if (locations.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CupertinoColors.systemFill.resolveFrom(context),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: Text(
                  '暂无具体馆藏地点记录。',
                  style: TextStyle(
                    color: CupertinoColors.secondaryLabel
                        .resolveFrom(context),
                  ),
                ),
              ),
            );
          }

          return CupertinoListSection.insetGrouped(
            children: locations.map((loc) {
              final isAvailable = loc.status.contains('在架') ||
                  loc.status.contains('可借') ||
                  loc.status.contains('在馆');

              final statusColor = isAvailable
                  ? CupertinoColors.systemGreen
                  : CupertinoColors.systemRed;

              return CupertinoListTile(
                leading: Icon(
                  CupertinoIcons.placemark_fill,
                  color: CupertinoColors.systemBlue.resolveFrom(context),
                  size: 20,
                ),
                title: Text(loc.location),
                additionalInfo: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor
                        .resolveFrom(context)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    loc.status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor.resolveFrom(context),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
      const SizedBox(height: 32),
    ],
  );
}

CupertinoListTile _buildCupertinoMetaTile(
  BuildContext context, {
  required IconData icon,
  required String label,
  required String value,
  bool isCode = false,
}) {
  return CupertinoListTile(
    leading: Icon(icon, size: 20),
    title: Text(label),
    subtitle: Text(
      value,
      style: TextStyle(
        fontFamily: isCode ? 'monospace' : null,
        fontWeight: isCode ? FontWeight.w700 : null,
      ),
    ),
  );
}
