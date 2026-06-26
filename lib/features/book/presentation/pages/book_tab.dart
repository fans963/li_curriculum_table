import 'package:animations/animations.dart';
import 'package:app_bar_m3e/app_bar_m3e.dart';
import 'package:flutter/material.dart';
import 'package:icon_button_m3e/icon_button_m3e.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_cupertino.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_detail_page.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_material.dart';
import 'package:signals/signals_flutter.dart';

class BookTab extends SignalStatefulWidget {
  const BookTab({super.key});

  @override
  State<BookTab> createState() => _BookTabState();
}

class _BookTabState extends State<BookTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final _searchController = TextEditingController();
  final _isLoading = signal(false);
  final _books = signal<List<BookInfo>>([]);
  final _error = signal<String?>(null);
  final _hasSearched = signal(false);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    _isLoading.value = true;
    _error.value = null;
    _hasSearched.value = true;

    try {
      final results = await searchBooks(title: query);
      if (!mounted) return;
      _books.value = results;
      _isLoading.value = false;
    } catch (e) {
      if (!mounted) return;
      _error.value = '检索失败，请检查网络后重试。';
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final ds = sl<SettingsController>().designStyle.value;

    if (AdaptiveStyle.isCupertino(ds)) {
      return buildBookCupertino(
        context,
        searchController: _searchController,
        onSearch: _performSearch,
        isLoading: _isLoading.value,
        hasSearched: _hasSearched.value,
        error: _error.value,
        books: _books.value,
        onBookTap: (book) => _showBookDetailsSheet(context, book),
      );
    }
    return _buildMaterial(context, ds);
  }

  Widget _buildMaterial(BuildContext context, DesignStyle ds) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const AppBarM3E(
        title: Text('图书搜寻'),
        centerTitle: true,
        shapeFamily: AppBarM3EShapeFamily.square,
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
                    leading: Icon(AppIcons.search(ds),
                        color: colorScheme.onSurfaceVariant),
                    trailing: [
                      if (_searchController.text.isNotEmpty)
                        IconButtonM3E(
                          icon: Icon(AppIcons.clear(ds)),
                          variant: IconButtonM3EVariant.tonal,
                          shape: IconButtonM3EShapeVariant.round,
                          onPressed: () => _searchController.clear(),
                        ),
                      IconButtonM3E(
                        icon: Icon(AppIcons.arrowForward(ds)),
                        variant: IconButtonM3EVariant.filled,
                        shape: IconButtonM3EShapeVariant.round,
                        onPressed: _performSearch,
                      ),
                    ],
                    onSubmitted: (_) => _performSearch(),
                    elevation: WidgetStateProperty.all(0),
                    backgroundColor: WidgetStateProperty.all(
                        colorScheme.surfaceContainerHigh),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                            color: colorScheme.outlineVariant
                                .withValues(alpha: 0.5)),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: buildMaterialBody(
                      context,
                      ds: ds,
                      isLoading: _isLoading.value,
                      error: _error.value,
                      hasSearched: _hasSearched.value,
                      books: _books.value,
                      onRetry: _performSearch,
                      onBookTap: (book, cardCenter, cardSize) =>
                          _showBookDetailsDialog(context, book, ds, cardCenter),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBookDetailsSheet(BuildContext context, BookInfo book) {
    showCupertinoBookDetailsSheet(context, book);
  }

  void _showBookDetailsDialog(
    BuildContext context,
    BookInfo book,
    DesignStyle ds,
    Offset cardCenter,
  ) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        pageBuilder: (context, animation, secondaryAnimation) {
          return BookDetailDialog(book: book, ds: ds);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeScaleTransition(animation: animation, child: child);
        },
      ),
    );
  }
}
