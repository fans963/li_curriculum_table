part of '../book_cupertino.dart';

class _CupertinoBookDetailDialog extends SignalStatefulWidget {
  final BookInfo book;
  const _CupertinoBookDetailDialog({required this.book});

  @override
  State<_CupertinoBookDetailDialog> createState() =>
      _CupertinoBookDetailDialogState();
}

class _CupertinoBookDetailDialogState
    extends State<_CupertinoBookDetailDialog> {
  late final BookCoverSignal _cover;
  final _copiedCallNo = signal(false);

  void _copyCallNo(String text) {
    Clipboard.setData(ClipboardData(text: text));
    _copiedCallNo.value = true;
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) _copiedCallNo.value = false;
    });
  }

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
    final book = widget.book;
    final enableBookCover = BookCoverSignal.isEnabled;

    return GlassDialog(
      borderRadius: 20,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enableBookCover) _CoverHeader(cover: _cover),
          if (!enableBookCover) _FallbackHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: _DetailContent(
                book: book,
                copiedCallNo: _copiedCallNo.value,
                onCopy: _copyCallNo,
              ),
            ),
          ),
          _CloseButton(),
        ],
      ),
    );
  }
}

/// Blurred background + floating cover header.
class _CoverHeader extends SignalWidget {
  final BookCoverSignal cover;
  const _CoverHeader({required this.cover});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: Builder(
              builder: (context) {
                final url = cover.url.value;
                if (url != null) {
                  return ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                      foregroundDecoration: BoxDecoration(
                        color: CupertinoColors.black.withValues(alpha: 0.2),
                      ),
                    ),
                  );
                }
                return Container(
                  color: CupertinoColors.secondarySystemBackground.resolveFrom(
                    context,
                  ),
                );
              },
            ),
          ),
          Center(
            child: Container(
              height: 150,
              width: 100,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _CoverImage(cover: cover),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fallback gradient header when covers are disabled.
class _FallbackHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            CupertinoColors.activeBlue
                .resolveFrom(context)
                .withValues(alpha: 0.12),
            CupertinoColors.activeBlue
                .resolveFrom(context)
                .withValues(alpha: 0.03),
          ],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: CupertinoColors.activeBlue
                .resolveFrom(context)
                .withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: CupertinoColors.activeBlue
                  .resolveFrom(context)
                  .withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Icon(
            CupertinoIcons.book_fill,
            size: 32,
            color: CupertinoColors.activeBlue.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// Detail scrollable content.
class _DetailContent extends StatelessWidget {
  final BookInfo book;
  final bool copiedCallNo;
  final void Function(String) onCopy;

  const _DetailContent({
    required this.book,
    required this.copiedCallNo,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.systemBlue.resolveFrom(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                book.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _DocTypeBadge(docType: book.docType),
          ],
        ),
        const SizedBox(height: 16),
        // Author & Publisher Group
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.secondarySystemBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _DetailInfoRow(icon: CupertinoIcons.person, text: book.author),
              if (book.publisher.isNotEmpty && book.publisher != '未知出版信息') ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Container(
                    height: 0.5,
                    color: CupertinoColors.separator.resolveFrom(context),
                  ),
                ),
                _DetailInfoRow(
                  icon: CupertinoIcons.building_2_fill,
                  text: book.publisher,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Call Number Copyable Card
        _CallNumberCard(
          callNo: book.callNo,
          copied: copiedCallNo,
          onCopy: onCopy,
        ),
        const SizedBox(height: 8),
        // Holdings Summary
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: blue.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(CupertinoIcons.collections, size: 18, color: blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  book.holdingsSummary,
                  style: TextStyle(
                    color: CupertinoColors.label.resolveFrom(context),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 0.5,
          color: CupertinoColors.separator.resolveFrom(context),
        ),
        const SizedBox(height: 12),
        _CupertinoHoldings(book: book),
      ],
    );
  }
}

/// Call number with copy button.
class _CallNumberCard extends StatelessWidget {
  final String callNo;
  final bool copied;
  final void Function(String) onCopy;

  const _CallNumberCard({
    required this.callNo,
    required this.copied,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final blue = CupertinoColors.systemBlue.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: blue.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Icon(CupertinoIcons.bookmark, size: 18, color: blue),
          const SizedBox(width: 8),
          Text(
            '索书号: ',
            style: TextStyle(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          Expanded(
            child: Text(
              callNo,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => onCopy(callNo),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: copied
                    ? Icon(
                        CupertinoIcons.checkmark_circle_fill,
                        key: const ValueKey('check'),
                        size: 18,
                        color: CupertinoColors.activeGreen.resolveFrom(context),
                      )
                    : Icon(
                        CupertinoIcons.doc_on_doc,
                        key: const ValueKey('copy'),
                        size: 18,
                        color: blue,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Info row used in detail dialog.
class _DetailInfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _DetailInfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: CupertinoColors.systemBlue
              .resolveFrom(context)
              .withValues(alpha: 0.8),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.3,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }
}

/// Close button row.
class _CloseButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}

/// Holdings section loaded asynchronously.
