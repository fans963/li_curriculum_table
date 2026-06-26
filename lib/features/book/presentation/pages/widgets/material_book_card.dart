part of '../book_material.dart';


class _BookWaterfallGrid extends StatelessWidget {
  final List<BookInfo> books;
  final DesignStyle ds;
  final void Function(BookInfo, Offset, Size) onBookTap;

  const _BookWaterfallGrid({
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
                    child: _BookWaterfallCard(
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
                    child: _BookWaterfallCard(
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

class _BookWaterfallCard extends SignalStatefulWidget {
  final BookInfo book;
  final DesignStyle ds;
  final void Function(Offset cardCenter, Size cardSize) onTap;

  const _BookWaterfallCard({
    required this.book,
    required this.ds,
    required this.onTap,
  });

  @override
  State<_BookWaterfallCard> createState() => _BookWaterfallCardState();
}

class _BookWaterfallCardState extends State<_BookWaterfallCard> {
  late final BookCoverSignal _cover;

  @override
  void initState() {
    super.initState();
    _cover = BookCoverSignal(detailUrl: widget.book.detailUrl, title: widget.book.title);
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
                  color: cs.surfaceContainerHighest,
                  child: Builder(builder: (context) {
                    if (_cover.loading.value) {
                      return Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: LoadingIndicatorM3E(
                            color: cs.primary,
                            constraints: BoxConstraints.tight(const Size(24, 24)),
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
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                        ),
                        errorWidget: (_, _, _) => Center(
                          child: Icon(
                            AppIcons.menuBook(widget.ds),
                            size: 40,
                            color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                          ),
                        ),
                      );
                    }
                    return Center(
                      child: Icon(
                        AppIcons.menuBook(widget.ds),
                        size: 40,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.2),
                      ),
                    );
                  }),
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
                        height: 1.3,
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
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        book.docType,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onPrimaryContainer,
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
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(AppIcons.book(widget.ds), size: 16, color: cs.primary),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              book.docType,
                              style: tt.labelSmall?.copyWith(
                                color: cs.onPrimaryContainer,
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
                const Divider(height: 1),
                const SizedBox(height: 10),
                InfoRow(icon: AppIcons.person(widget.ds), text: book.author, ds: widget.ds),
                if (book.publisher != '未知出版信息' && book.publisher.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  InfoRow(icon: AppIcons.business(widget.ds), text: book.publisher, ds: widget.ds),
                ],
                const SizedBox(height: 5),
                InfoRow(icon: AppIcons.bookmark(widget.ds), text: '索书: ${book.callNo}', ds: widget.ds, isMonospace: true),
                const SizedBox(height: 5),
                InfoRow(icon: AppIcons.libraryBooks(widget.ds), text: book.holdingsSummary, ds: widget.ds),
              ],
            ),
          );

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
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: cardContent,
      ),
    );
  }
}

