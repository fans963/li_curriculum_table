import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';

class BookTab extends ConsumerStatefulWidget {
  const BookTab({super.key});

  @override
  ConsumerState<BookTab> createState() => _BookTabState();
}

class _BookTabState extends ConsumerState<BookTab> {
  final _searchController = TextEditingController();
  bool _isLoading = false;
  List<BookInfo> _books = [];
  String? _error;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {}); // Update search bar trailing icon
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    try {
      final results = await searchBooks(title: query);
      if (!mounted) return;
      setState(() {
        _books = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '检索失败，请检查网络后重试。';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = ref.watch(settingsControllerProvider).designStyle;

    if (AdaptiveStyle.isCupertino(ds)) {
      return _buildCupertino(context);
    }
    return _buildMaterial(context);
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ds = ref.watch(settingsControllerProvider).designStyle;

    return Scaffold(
      appBar: AppBar(
        title: const Text('图书搜寻'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: '输入书名检索馆藏，例如 "计算机"',
                    leading: Icon(AppIcons.search(ds), color: colorScheme.onSurfaceVariant),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButton(
                          icon: Icon(AppIcons.clear(ds)),
                          onPressed: () => _searchController.clear(),
                        ),
                      IconButton(
                        icon: Icon(AppIcons.arrowForward(ds), color: colorScheme.primary),
                        onPressed: _performSearch,
                      ),
                    ],
                    onSubmitted: (_) => _performSearch(),
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(colorScheme.surfaceContainerHigh),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                Expanded(child: _buildMaterialBody(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Cupertino ─────────────────────────────────────────────────────────────

  Widget _buildCupertino(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: const Text('图书搜寻'),
            backgroundColor: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            border: null,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: CupertinoSearchTextField(
                controller: _searchController,
                placeholder: '输入书名检索馆藏',
                onSubmitted: (_) => _performSearch(),
              ),
            ),
          ),
          _buildCupertinoContent(context),
        ],
      ),
    );
  }

  Widget _buildCupertinoContent(BuildContext context) {
    if (_isLoading) {
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

    if (_error != null) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(CupertinoIcons.wifi_slash, size: 64, color: CupertinoColors.systemRed),
              const SizedBox(height: 16),
              const Text('出现错误', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: CupertinoColors.secondaryLabel)),
              const SizedBox(height: 24),
              CupertinoButton.filled(
                onPressed: _performSearch,
                child: const Text('重新尝试'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: CupertinoColors.systemFill,
                ),
                child: const Icon(CupertinoIcons.collections, size: 72, color: CupertinoColors.systemBlue),
              ),
              const SizedBox(height: 24),
              const Text(
                '南理工图书搜寻',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                '输入您想查找的书名，即刻查询图书馆馆藏',
                style: TextStyle(color: CupertinoColors.secondaryLabel),
              ),
            ],
          ),
        ),
      );
    }

    if (_books.isEmpty) {
      return const SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.search, size: 64, color: CupertinoColors.systemGrey),
              SizedBox(height: 16),
              Text('未找到相关书籍', style: TextStyle(fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('换个简短的关键词再试试', style: TextStyle(color: CupertinoColors.secondaryLabel)),
            ],
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        CupertinoListSection.insetGrouped(
          children: _books.map((book) {
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
              onTap: () => _showBookDetailsSheet(context, book),
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ]),
    );
  }

  Widget _buildMaterialBody(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3),
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

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.cloudOff(ds),
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                '出现错误',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                icon: Icon(AppIcons.refresh(ds), size: 18),
                label: const Text('重新尝试'),
                onPressed: _performSearch,
              ),
            ],
          ),
        ),
      );
    }

    if (!_hasSearched) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Beautiful Gradient Icon Container
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

    if (_books.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                AppIcons.searchOff(ds),
                size: 64,
                color: colorScheme.outline,
              ),
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

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        return _buildBookCard(context, book);
      },
    );
  }

  Widget _buildBookCard(BuildContext context, BookInfo book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = ProviderScope.containerOf(context).read(settingsControllerProvider).designStyle;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showBookDetailsSheet(context, book),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book spine indicator
              Container(
                width: 44,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: Icon(
                  AppIcons.menuBook(ds),
                  color: colorScheme.onSecondaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              // Book text details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and DocType badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book.title,
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.docType,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Author & Publisher
                    Row(
                      children: [
                        Icon(
                          AppIcons.person(ds),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.author,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          AppIcons.business(ds),
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            book.publisher,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Call Number & Summary
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                AppIcons.bookmark(ds),
                                size: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '索书号: ${book.callNo}',
                                style: textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            book.holdingsSummary,
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                AppIcons.chevronRight(ds),
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBookDetailsSheet(BuildContext context, BookInfo book) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ds = ref.read(settingsControllerProvider).designStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),

                  // Header with Book Title
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          book.title,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: colorScheme.primary,
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
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          book.docType,
                          style: textTheme.labelMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),

                  // Book Metadata Grid
                  _buildMetaItem(context, '索书号', book.callNo, isCode: true),
                  _buildMetaItem(context, '责任者/作者', book.author),
                  _buildMetaItem(context, '出版与印刷项', book.publisher),
                  _buildMetaItem(context, '馆藏概况', book.holdingsSummary),

                  const SizedBox(height: 20),
                  Text(
                    '具体馆藏分布与借阅状态',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Specific holdings list (Lazy loaded)
                  FutureBuilder<List<BookLocation>>(
                    future: fetchBookLocations(detailUrl: book.detailUrl),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Column(
                          children: [
                            const SizedBox(height: 8),
                            const LinearProgressIndicator(),
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                '正在向南理工图书馆获取实时馆藏位置...',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
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
                            color: colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(AppIcons.errorOutline(ds), color: colorScheme.onErrorContainer),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '获取馆藏位置失败，请重试。',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onErrorContainer,
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
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '暂无具体馆藏地点记录。',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: locations.length,
                        itemBuilder: (context, index) {
                          final loc = locations[index];
                          final isAvailable = loc.status.contains('在架') || 
                                              loc.status.contains('可借') || 
                                              loc.status.contains('在馆');

                          final chipBgColor = isAvailable
                              ? colorScheme.primaryContainer.withValues(alpha: 0.4)
                              : colorScheme.errorContainer.withValues(alpha: 0.4);
                          final chipTextColor = isAvailable
                              ? colorScheme.primary
                              : colorScheme.error;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  AppIcons.place(ds),
                                  color: colorScheme.primary.withValues(alpha: 0.8),
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    loc.location,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chipBgColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    loc.status,
                                    style: textTheme.labelSmall?.copyWith(
                                      color: chipTextColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetaItem(BuildContext context, String label, String value, {bool isCode = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(
              fontFamily: isCode ? 'monospace' : null,
              fontWeight: isCode ? FontWeight.w700 : null,
              color: colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
