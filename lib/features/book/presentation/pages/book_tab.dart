import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_cupertino.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_material.dart';
import 'package:signals/signals_flutter.dart';

class BookTab extends StatefulWidget {
  const BookTab({super.key});

  @override
  State<BookTab> createState() => _BookTabState();
}

class _BookTabState extends State<BookTab> {
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
    return SignalBuilder(builder: (context) {
      final ds = sl<SettingsController>().designStyle.value;

      if (AdaptiveStyle.isCupertino(ds)) {
        return buildBookCupertino(
          context,
          searchController: _searchController,
          onSearch: _performSearch,
          isLoading: _isLoading,
          hasSearched: _hasSearched,
          error: _error,
          books: _books,
          onBookTap: (book) => _showBookDetailsSheet(context, book),
        );
      }
      return _buildMaterial(context, ds);
    });
  }

  // ─── Material ──────────────────────────────────────────────────────────────

  Widget _buildMaterial(BuildContext context, DesignStyle ds) {
    final colorScheme = Theme.of(context).colorScheme;

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
                Expanded(
                  child: buildMaterialBody(
                    context,
                    ds: ds,
                    isLoading: _isLoading,
                    error: _error,
                    hasSearched: _hasSearched,
                    books: _books,
                    onRetry: _performSearch,
                    onBookTap: (book) => _showBookDetailsSheet(context, book),
                    onShowDetails: _showMaterialDetailsSheet,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Book Details Sheet (routing layer) ────────────────────────────────────

  void _showBookDetailsSheet(BuildContext context, BookInfo book) {
    final ds = sl<SettingsController>().designStyle.value;

    if (AdaptiveStyle.isCupertino(ds)) {
      showCupertinoBookDetailsSheet(context, book);
      return;
    }

    _showMaterialDetailsSheet(context, book, ds);
  }

  void _showMaterialDetailsSheet(
    BuildContext context,
    BookInfo book,
    DesignStyle ds,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
                  buildMetaItem(context, '索书号', book.callNo, isCode: true),
                  buildMetaItem(context, '责任者/作者', book.author),
                  buildMetaItem(context, '出版与印刷项', book.publisher),
                  buildMetaItem(context, '馆藏概况', book.holdingsSummary),

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
                  buildMaterialHoldings(context, book, ds),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
