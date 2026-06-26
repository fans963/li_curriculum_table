part of '../book_cupertino.dart';

// Cupertino Book Card — with cover image + signal lazy loading
// ═══════════════════════════════════════════════════════════════════════════

class _CupertinoBookCard extends StatefulWidget {
  final BookInfo book;
  final VoidCallback onTap;

  const _CupertinoBookCard({required this.book, required this.onTap});

  @override
  State<_CupertinoBookCard> createState() => _CupertinoBookCardState();
}

class _CupertinoBookCardState extends State<_CupertinoBookCard> {
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
    final cs = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final enableBookCover = BookCoverSignal.isEnabled;

    final cardContent = enableBookCover
        ? _CoverCardContent(book: widget.book, cover: _cover, cs: cs, secondary: secondary)
        : _TextOnlyCardContent(book: widget.book, cs: cs, secondary: secondary);

    return GestureDetector(
      onTap: widget.onTap,
      child: GlassCard(
        borderRadius: 12,
        shadowAlpha: 0.03,
        backgroundColor: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context).withValues(alpha: 0.6),
        borderColor: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2),
        child: cardContent,
      ),
    );
  }
}

/// Cover image + title card content.
class _CoverCardContent extends StatelessWidget {
  final BookInfo book;
  final BookCoverSignal cover;
  final Color cs;
  final Color secondary;

  const _CoverCardContent({
    required this.book,
    required this.cover,
    required this.cs,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2 / 3,
          child: Container(
            color: CupertinoColors.systemFill.resolveFrom(context),
            child: _CoverImage(cover: cover),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                book.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: cs, height: 1.25),
              ),
              const SizedBox(height: 4),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: secondary),
              ),
              const SizedBox(height: 6),
              _DocTypeBadge(docType: book.docType),
            ],
          ),
        ),
      ],
    );
  }
}

/// Text-only card content (no cover).
class _TextOnlyCardContent extends StatelessWidget {
  final BookInfo book;
  final Color cs;
  final Color secondary;

  const _TextOnlyCardContent({
    required this.book,
    required this.cs,
    required this.secondary,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemBlue.resolveFrom(context).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(CupertinoIcons.book, size: 14, color: CupertinoColors.systemBlue.resolveFrom(context)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: cs, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    _DocTypeBadge(docType: book.docType),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          _BookInfoRow(icon: CupertinoIcons.person, text: book.author, color: secondary),
          if (book.publisher != '未知出版信息' && book.publisher.isNotEmpty) ...[
            const SizedBox(height: 4),
            _BookInfoRow(icon: CupertinoIcons.building_2_fill, text: book.publisher, color: secondary),
          ],
          const SizedBox(height: 4),
          _BookInfoRow(icon: CupertinoIcons.bookmark, text: '索书: ${book.callNo}', color: secondary, isMonospace: true),
          const SizedBox(height: 4),
          _BookInfoRow(icon: CupertinoIcons.collections, text: book.holdingsSummary, color: secondary),
        ],
      ),
    );
  }
}

/// Reusable cover image widget backed by [BookCoverSignal].
class _CoverImage extends SignalWidget {
  final BookCoverSignal cover;
  const _CoverImage({required this.cover});

  @override
  Widget build(BuildContext context) {
    if (cover.loading.value) {
        return const Center(child: CupertinoActivityIndicator(radius: 10));
      }
      final url = cover.url.value;
      if (url != null) {
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          httpHeaders: url.contains('doubanio.com') ? const {'Referer': 'https://book.douban.com/'} : const {},
          placeholder: (_, _) => _bookPlaceholder(context),
          errorWidget: (_, _, _) => _bookPlaceholder(context),
        );
      }
      return _bookPlaceholder(context);
  }

  static Widget _bookPlaceholder(BuildContext context) {
    return Center(child: Icon(CupertinoIcons.book, size: 40, color: CupertinoColors.systemGrey3.resolveFrom(context)));
  }
}

/// Small doc-type badge chip.
class _DocTypeBadge extends StatelessWidget {
  final String docType;
  const _DocTypeBadge({required this.docType});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.resolveFrom(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        docType,
        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: CupertinoColors.systemBlue.resolveFrom(context)),
      ),
    );
  }
}

/// Compact info row used in text-only card.
class _BookInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool isMonospace;

  const _BookInfoRow({
    required this.icon,
    required this.text,
    required this.color,
    this.isMonospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontFamily: isMonospace ? 'monospace' : null,
              fontWeight: isMonospace ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Cupertino Book Details — centered dialog style
// ═══════════════════════════════════════════════════════════════════════════

void showCupertinoBookDetailsSheet(BuildContext context, BookInfo book) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'book-detail',
    barrierColor: CupertinoColors.black.withValues(alpha: 0.4),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, animation, secondaryAnimation) {
      return _CupertinoBookDetailDialog(book: book);
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      final t = curved.value;
      final scale = 0.85 + 0.15 * t;
      return Transform.scale(scale: scale, child: Opacity(opacity: t, child: child));
    },
  );
}

