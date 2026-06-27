import 'package:animations/animations.dart';
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
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/m3e_adv_dropdown.dart';
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

  // Advanced search params
  final _advSearchType = signal('title');
  final _advDoctype = signal('ALL');
  final _advDept = signal('ALL');
  final _advSort = signal('CATA_DATE');
  final _advOrderby = signal('DESC');
  final _advDisplaypg = signal(20);
  final _advExpanded = signal(false);
  final _advPage = signal(1);
  final _totalCount = signal(0);

  int get _totalPages => _totalCount.value == 0
      ? 1
      : ((_totalCount.value - 1) ~/ _advDisplaypg.value + 1);

  static const _searchTypeLabels = {
    'title': '题名',
    'author': '责任者',
    'publisher': '出版社',
    'isbn': 'ISBN',
    'keyword': '关键词',
  };
  static const _doctypeLabels = {
    'ALL': '所有书刊',
    '01': '中文图书',
    '02': '西文图书',
    '11': '中文期刊',
    '12': '西文期刊',
  };
  static const _deptLabels = {'ALL': '所有校区', '00': '南京校区', '06': '江阴校区'};
  static const _sortLabels = {
    'CATA_DATE': '入藏日期',
    'M_TITLE': '题名',
    'M_AUTHOR': '责任者',
    'M_CALL_NO': '索书号',
    'M_PUBLISHER': '出版社',
    'M_PUB_YEAR': '出版日期',
  };
  static const _displaypgOptions = [20, 30, 50, 100];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _isAdvancedDefault =>
      _advSearchType.value == 'title' &&
      _advDoctype.value == 'ALL' &&
      _advDept.value == 'ALL' &&
      _advSort.value == 'CATA_DATE' &&
      _advOrderby.value == 'DESC' &&
      _advDisplaypg.value == 20;

  Future<void> _performSearch({bool changePage = false}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (!changePage) _advPage.value = 1;

    _isLoading.value = true;
    _error.value = null;
    _hasSearched.value = true;

    try {
      final result = (_isAdvancedDefault && _advPage.value == 1)
          ? await searchBooks(title: query)
          : await searchBooksAdvanced(
              params: BookSearchParams(
                searchType: _advSearchType.value,
                query: query,
                doctype: _advDoctype.value,
                langCode: 'ALL',
                displaypg: _advDisplaypg.value,
                sort: _advSort.value,
                orderby: _advOrderby.value,
                dept: _advDept.value,
                showmode: 'list',
                page: _advPage.value,
              ),
            );
      if (!mounted) return;
      _books.value = result.books;
      _totalCount.value = result.totalCount;
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
        advSearchType: _advSearchType.value,
        advDoctype: _advDoctype.value,
        advDept: _advDept.value,
        advSort: _advSort.value,
        advOrderby: _advOrderby.value,
        advDisplaypg: _advDisplaypg.value,
        searchTypeLabels: _searchTypeLabels.keys.toList(),
        doctypeLabels: _doctypeLabels.keys.toList(),
        deptLabels: _deptLabels.keys.toList(),
        sortLabels: _sortLabels.keys.toList(),
        displaypgOptions: _displaypgOptions,
        searchTypeMap: _searchTypeLabels,
        doctypeMap: _doctypeLabels,
        deptMap: _deptLabels,
        sortMap: _sortLabels,
        onAdvChanged: <String, void Function(String)>{
          'searchType': (v) {
            _advSearchType.value = v;
          },
          'doctype': (v) {
            _advDoctype.value = v;
          },
          'dept': (v) {
            _advDept.value = v;
          },
          'sort': (v) {
            _advSort.value = v;
          },
          'orderby': (v) {
            _advOrderby.value = v;
          },
          'displaypg': (v) {
            _advDisplaypg.value = int.parse(v);
          },
        },
        page: _advPage.value,
        totalCount: _totalCount.value,
        totalPages: _totalPages,
        onPageChanged: (page) {
          _advPage.value = page;
          _performSearch(changePage: true);
        },
      );
    }
    return _buildMaterial(context, ds);
  }

  Widget _buildPaginationBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pg = _advPage.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton.filledTonal(
            icon: const Icon(Icons.navigate_before, size: 18),
            onPressed: pg > 1
                ? () {
                    _advPage.value = pg - 1;
                    _performSearch(changePage: true);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(minimumSize: const Size(36, 32)),
          ),
          const SizedBox(width: 12),
          Text(
            '$pg / $_totalPages (${_totalCount.value} 条)',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            icon: const Icon(Icons.navigate_next, size: 18),
            onPressed: pg < _totalPages
                ? () {
                    _advPage.value = pg + 1;
                    _performSearch(changePage: true);
                  }
                : null,
            visualDensity: VisualDensity.compact,
            style: IconButton.styleFrom(minimumSize: const Size(36, 32)),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSearchPanel(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final adv = _advExpanded.value;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => _advExpanded.value = !adv,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  size: 16,
                  color: _isAdvancedDefault ? cs.onSurfaceVariant : cs.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  _isAdvancedDefault ? '高级检索' : '已启用高级检索',
                  style: tt.labelSmall?.copyWith(
                    color: _isAdvancedDefault
                        ? cs.onSurfaceVariant
                        : cs.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const Spacer(),
                Icon(
                  adv ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        if (adv) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: 检索字段 + 文献类型
                Row(
                  children: [
                    _advDropdown(
                      context,
                      label: '检索字段',
                      value: _advSearchType.value,
                      items: _searchTypeLabels,
                      onChanged: (v) => _advSearchType.value = v,
                    ),
                    const SizedBox(width: 10),
                    _advDropdown(
                      context,
                      label: '文献类型',
                      value: _advDoctype.value,
                      items: _doctypeLabels,
                      onChanged: (v) => _advDoctype.value = v,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Row 2: 校区 + 排序
                Row(
                  children: [
                    _advDropdown(
                      context,
                      label: '校区',
                      value: _advDept.value,
                      items: _deptLabels,
                      onChanged: (v) => _advDept.value = v,
                    ),
                    const SizedBox(width: 10),
                    _advDropdown(
                      context,
                      label: '排序',
                      value: _advSort.value,
                      items: _sortLabels,
                      onChanged: (v) => _advSort.value = v,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Row 3: 排序方向 + 每页数量
                Row(
                  children: [
                    Text(
                      '每页',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ToggleButtons(
                      isSelected: _displaypgOptions
                          .map((n) => n == _advDisplaypg.value)
                          .toList(),
                      onPressed: (i) =>
                          _advDisplaypg.value = _displaypgOptions[i],
                      borderRadius: BorderRadius.circular(20),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 32,
                      ),
                      children: _displaypgOptions
                          .map(
                            (n) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(
                                '$n',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const Spacer(),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'DESC',
                          label: Text(
                            '最新优先',
                            style: TextStyle(
                              fontSize: 12,
                              color: _advOrderby.value == 'DESC'
                                  ? cs.onPrimary
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: 'asc',
                          label: Text(
                            '最早优先',
                            style: TextStyle(
                              fontSize: 12,
                              color: _advOrderby.value == 'asc'
                                  ? cs.onPrimary
                                  : cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                      selected: {_advOrderby.value},
                      onSelectionChanged: (s) => _advOrderby.value = s.first,
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        padding: WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _advDropdown(
    BuildContext context, {
    required String label,
    required String value,
    required Map<String, String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Expanded(
      child: M3EAdvDropdown(
        label: label,
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMaterial(BuildContext context, DesignStyle ds) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Compact header: search bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.outlineVariant.withValues(
                          alpha: 0.3,
                        ),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: '输入书名检索馆藏，例如 "计算机"',
                    leading: Icon(
                      AppIcons.search(ds),
                      color: colorScheme.onSurfaceVariant,
                    ),
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
                      colorScheme.surfaceContainerHigh,
                    ),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ), // end compact header
                // Advanced search toggle + panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAdvancedSearchPanel(context),
                ),
                // Pagination controls
                if (_hasSearched.value && _totalCount.value > 0)
                  _buildPaginationBar(context),
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
