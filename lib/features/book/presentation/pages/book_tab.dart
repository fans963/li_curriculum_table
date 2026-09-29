import 'package:animations/animations.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_detail_page.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_material.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/book_adv_dropdown.dart';
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

    return _buildMaterial(context, ds);
  }

  Widget _buildPaginationBar(BuildContext context, DesignStyle ds) {
    final cs = Theme.of(context).colorScheme;
    final pg = _advPage.value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          adaptiveIconButton(
            designStyle: ds,
            icon: const Icon(Icons.navigate_before, size: 18),
            size: 32,
            onPressed: pg > 1
                ? () {
                    _advPage.value = pg - 1;
                    _performSearch(changePage: true);
                  }
                : null,
          ),
          const SizedBox(width: 12),
          Text(
            '$pg / $_totalPages (${_totalCount.value} 条)',
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          adaptiveIconButton(
            designStyle: ds,
            icon: const Icon(Icons.navigate_next, size: 18),
            size: 32,
            onPressed: pg < _totalPages
                ? () {
                    _advPage.value = pg + 1;
                    _performSearch(changePage: true);
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSearchPanel(BuildContext context, DesignStyle ds) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final adv = _advExpanded.value;

    final panelContent = Column(
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
        Builder(
          builder: (context) {
            final isLiquid =
                UiStyleRegistry.resolveConcreteStyle(ds) ==
                DesignStyle.cupertino;
            if (isLiquid) {
              return Row(
                children: [
                  Text(
                    '每页',
                    style: tt.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 140,
                    height: 32,
                    child: GlassSegmentedControl(
                      segments: _displaypgOptions
                          .map((n) => GlassSegment(label: '$n'))
                          .toList(),
                      selectedIndex: _displaypgOptions
                          .indexOf(_advDisplaypg.value)
                          .clamp(0, 3),
                      onSegmentSelected: (i) =>
                          _advDisplaypg.value = _displaypgOptions[i],
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 160,
                    height: 32,
                    child: GlassSegmentedControl(
                      segments: const [
                        GlassSegment(label: '最新优先'),
                        GlassSegment(label: '最早优先'),
                      ],
                      selectedIndex: _advOrderby.value == 'DESC' ? 0 : 1,
                      onSegmentSelected: (i) =>
                          _advOrderby.value = i == 0 ? 'DESC' : 'asc',
                    ),
                  ),
                ],
              );
            }
            return Row(
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
            );
          },
        ),
      ],
    );

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
          UiStyleRegistry.resolve(ds).buildCard(
            context: context,
            padding: const EdgeInsets.all(14),
            borderRadius: 16,
            child: panelContent,
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
      child: BookAdvDropdown(
        label: label,
        value: value,
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMaterial(BuildContext context, DesignStyle ds) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = UiStyleRegistry.resolve(ds);

    return ColoredBox(
      color: style.pageBackgroundColor(colorScheme),
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              children: [
                // Compact header: search bar
                style.buildHeaderBar(
                  context: context,
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: style.buildSearchBar(
                          context: context,
                          controller: _searchController,
                          placeholder: '输入书名检索馆藏，例如 "计算机"',
                          onSubmitted: (_) => _performSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      adaptiveIconButton(
                        designStyle: ds,
                        icon: Icon(AppIcons.arrowForward(ds)),
                        tooltip: '搜索',
                        onPressed: _performSearch,
                      ),
                    ],
                  ),
                ), // end compact header
                // Advanced search toggle + panel
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildAdvancedSearchPanel(context, ds),
                ),
                // Pagination controls
                if (_hasSearched.value && _totalCount.value > 0)
                  _buildPaginationBar(context, ds),
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
