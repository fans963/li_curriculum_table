import 'package:cached_network_image/cached_network_image.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:signals/signals_flutter.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/presentation/info_row.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/domain/book_cover_loader.dart';

/// iOS 26 Liquid Glass waterfall grid for book search results.
class LiquidGlassBookWaterfallGrid extends StatelessWidget {
  final List<BookInfo> books;
  final DesignStyle ds;
  final void Function(BookInfo, Offset, Size) onBookTap;

  const LiquidGlassBookWaterfallGrid({
    super.key,
    required this.books,
    required this.ds,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final leftBooks = <BookInfo>[];
    final rightBooks = <BookInfo>[];
    for (var i = 0; i < books.length; i++) {
      if (i.isEven) {
        leftBooks.add(books[i]);
      } else {
        rightBooks.add(books[i]);
      }
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
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
                    child: LiquidGlassBookWaterfallCard(
                      book: book,
                      ds: ds,
                      onTap: (center, size) => onBookTap(book, center, size),
                    ),
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
                    child: LiquidGlassBookWaterfallCard(
                      book: book,
                      ds: ds,
                      onTap: (center, size) => onBookTap(book, center, size),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// iOS 26 Liquid Glass waterfall card with continuous superellipse curvature,
/// frosted surface reflection, and Apple-standard typography.
class LiquidGlassBookWaterfallCard extends SignalStatefulWidget {
  final BookInfo book;
  final DesignStyle ds;
  final void Function(Offset cardCenter, Size cardSize) onTap;

  const LiquidGlassBookWaterfallCard({
    super.key,
    required this.book,
    required this.ds,
    required this.onTap,
  });

  @override
  State<LiquidGlassBookWaterfallCard> createState() =>
      _LiquidGlassBookWaterfallCardState();
}

class _LiquidGlassBookWaterfallCardState
    extends State<LiquidGlassBookWaterfallCard> {
  late final BookCoverSignal _cover;

  @override
  void initState() {
    super.initState();
    _cover = BookCoverSignal(
      detailUrl: widget.book.detailUrl,
      title: widget.book.title,
    );
  }

  @override
  void dispose() {
    _cover.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final book = widget.book;
    final cardKey = GlobalKey();
    final enableBookCover = BookCoverSignal.isEnabled;

    final cardContent = enableBookCover
        ? Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 3 / 4,
                child: Container(
                  color: cs.onSurface.withValues(alpha: 0.05),
                  child: Builder(
                    builder: (context) {
                      if (_cover.loading.value) {
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: GlassProgressIndicator.circular(
                              size: 20,
                              color: cs.primary,
                            ),
                          ),
                        );
                      }
                      final url = _cover.url.value;
                      if (url != null) {
                        return CachedNetworkImage(
                          imageUrl: url,
                          fit: BoxFit.cover,
                          httpHeaders: url.contains('doubanio.com')
                              ? const {'Referer': 'https://book.douban.com/'}
                              : const {},
                          placeholder: (_, _) => Center(
                            child: Icon(
                              AppIcons.menuBook(widget.ds),
                              size: 40,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                            ),
                          ),
                          errorWidget: (_, _, _) => Center(
                            child: Icon(
                              AppIcons.menuBook(widget.ds),
                              size: 40,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                            ),
                          ),
                        );
                      }
                      return Center(
                        child: Icon(
                          AppIcons.menuBook(widget.ds),
                          size: 40,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.25),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book.docType,
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        AppIcons.book(widget.ds),
                        size: 16,
                        color: cs.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            book.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: tt.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.docType,
                              style: tt.labelSmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: cs.outlineVariant.withValues(alpha: 0.25),
                ),
                const SizedBox(height: 10),
                InfoRow(
                  icon: AppIcons.person(widget.ds),
                  text: book.author,
                  ds: widget.ds,
                ),
                if (book.publisher != '未知出版信息' &&
                    book.publisher.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  InfoRow(
                    icon: AppIcons.business(widget.ds),
                    text: book.publisher,
                    ds: widget.ds,
                  ),
                ],
                const SizedBox(height: 5),
                InfoRow(
                  icon: AppIcons.bookmark(widget.ds),
                  text: '索书: ${book.callNo}',
                  ds: widget.ds,
                  isMonospace: true,
                ),
                const SizedBox(height: 5),
                InfoRow(
                  icon: AppIcons.libraryBooks(widget.ds),
                  text: book.holdingsSummary,
                  ds: widget.ds,
                ),
              ],
            ),
          );

    final style = UiStyleRegistry.resolve(widget.ds);

    return GestureDetector(
      onTap: () {
        final box = cardKey.currentContext?.findRenderObject() as RenderBox?;
        if (box != null) {
          final size = box.size;
          final pos = box.localToGlobal(Offset.zero);
          widget.onTap(pos + Offset(size.width / 2, size.height / 2), size);
        }
      },
      child: Container(
        key: cardKey,
        child: style.buildCard(
          context: context,
          padding: EdgeInsets.zero,
          borderRadius: 16,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
