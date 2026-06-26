import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_icons.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/domain/book_cover_loader.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/book_material.dart';
import 'package:li_curriculum_table/core/presentation/info_row.dart';
import 'package:signals/signals_flutter.dart';
import 'package:m3e_core/m3e_core.dart';

class BookDetailDialog extends StatefulWidget {
  final BookInfo book;
  final DesignStyle ds;
  final VoidCallback? onClose;

  const BookDetailDialog({
    super.key,
    required this.book,
    required this.ds,
    this.onClose,
  });

  @override
  State<BookDetailDialog> createState() => _BookDetailDialogState();
}

class _BookDetailDialogState extends State<BookDetailDialog> {
  late final BookCoverSignal _cover;
  bool _copiedCallNo = false;

  void _copyCallNo(String text) {
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copiedCallNo = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _copiedCallNo = false);
    });
  }

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
    final ds = widget.ds;
    final enableBookCover = BookCoverSignal.isEnabled;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (enableBookCover) _MaterialCoverHeader(cover: _cover, cs: cs, ds: ds),
              if (!enableBookCover) _MaterialFallbackHeader(cs: cs, ds: ds),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: _MaterialDetailContent(
                    book: book,
                    ds: ds,
                    copiedCallNo: _copiedCallNo,
                    onCopy: _copyCallNo,
                  ),
                ),
              ),
              _MaterialCloseButton(onClose: widget.onClose),
            ],
          ),
        ),
      ),
    );
  }
}

/// Blurred cover header for Material detail dialog.
class _MaterialCoverHeader extends SignalWidget {
  final BookCoverSignal cover;
  final ColorScheme cs;
  final DesignStyle ds;

  const _MaterialCoverHeader({required this.cover, required this.cs, required this.ds});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.antiAlias,
        children: [
          Positioned.fill(
            child: Builder(builder: (context) {
              final url = cover.url.value;
              if (url != null) {
                return ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
                    ),
                    foregroundDecoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.25)),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [cs.primaryContainer, cs.secondaryContainer.withValues(alpha: 0.5)],
                  ),
                ),
              );
            }),
          ),
          Center(
            child: Container(
              height: 140,
              width: 105,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              clipBehavior: Clip.antiAlias,
              child: Builder(builder: (context) {
                final url = cover.url.value;
                if (url != null) {
                  return CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    httpHeaders: url.contains('doubanio.com') ? const {'Referer': 'https://book.douban.com/'} : const {},
                    placeholder: (_, _) => _placeholder(cs, ds),
                    errorWidget: (_, _, _) => _placeholder(cs, ds),
                  );
                }
                return _placeholder(cs, ds);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(ColorScheme cs, DesignStyle ds) {
    return Container(
      color: cs.surfaceContainerHighest,
      child: Icon(AppIcons.menuBook(ds), size: 40, color: cs.onSurfaceVariant.withValues(alpha: 0.3)),
    );
  }
}

/// Fallback header when covers are disabled.
class _MaterialFallbackHeader extends StatelessWidget {
  final ColorScheme cs;
  final DesignStyle ds;

  const _MaterialFallbackHeader({required this.cs, required this.ds});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary.withValues(alpha: 0.15), cs.secondary.withValues(alpha: 0.05)],
        ),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.6),
            shape: BoxShape.circle,
            border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Icon(AppIcons.menuBook(ds), size: 36, color: cs.primary),
        ),
      ),
    );
  }
}

/// Detail content section for Material.
class _MaterialDetailContent extends StatelessWidget {
  final BookInfo book;
  final DesignStyle ds;
  final bool copiedCallNo;
  final void Function(String) onCopy;

  const _MaterialDetailContent({
    required this.book,
    required this.ds,
    required this.copiedCallNo,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(book.title, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, height: 1.25, color: cs.onSurface)),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.primary.withValues(alpha: 0.2), width: 1),
              ),
              child: Text(book.docType, style: tt.labelMedium?.copyWith(color: cs.onPrimaryContainer, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Author & Publisher Card
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              InfoRow(icon: AppIcons.person(ds), text: book.author, ds: ds),
              if (book.publisher.isNotEmpty && book.publisher != '未知出版信息') ...[
                const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, thickness: 0.5)),
                InfoRow(icon: AppIcons.business(ds), text: book.publisher, ds: ds),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Call Number Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.primary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.bookmark(ds), size: 18, color: cs.primary),
              const SizedBox(width: 8),
              Text('索书号: ', style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w500)),
              Expanded(
                child: SelectableText(book.callNo, style: tt.bodyMedium?.copyWith(fontFamily: 'monospace', fontWeight: FontWeight.bold, color: cs.onSurface)),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onCopy(book.callNo),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: copiedCallNo
                        ? Icon(Icons.check_circle, key: const ValueKey('check'), size: 18, color: Colors.green.shade600)
                        : Icon(Icons.copy_rounded, key: const ValueKey('copy'), size: 18, color: cs.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Holdings Summary Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: cs.secondaryContainer.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              Icon(AppIcons.libraryBooks(ds), size: 18, color: cs.secondary),
              const SizedBox(width: 8),
              Expanded(child: Text(book.holdingsSummary, style: tt.bodyMedium?.copyWith(color: cs.onSecondaryContainer, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Divider(height: 1),
        const SizedBox(height: 12),
        buildMaterialHoldings(context, book, ds),
      ],
    );
  }


}

/// Close button.
class _MaterialCloseButton extends StatelessWidget {
  final VoidCallback? onClose;
  const _MaterialCloseButton({this.onClose});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 16, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          M3EFilledButton(
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else {
                Navigator.pop(context);
              }
            },
            size: M3EButtonSize.md,
            shape: M3EButtonShape.round,
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
