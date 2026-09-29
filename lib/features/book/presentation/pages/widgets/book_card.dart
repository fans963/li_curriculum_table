import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/rust/api/book.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/liquid_glass_book_card.dart';
import 'package:li_curriculum_table/features/book/presentation/pages/widgets/m3e_book_card.dart';

export 'liquid_glass_book_card.dart';
export 'm3e_book_card.dart';

/// Adaptive book waterfall grid that delegates to either [M3eBookWaterfallGrid]
/// or [LiquidGlassBookWaterfallGrid] according to the active [DesignStyle].
class BookWaterfallGrid extends StatelessWidget {
  final List<BookInfo> books;
  final DesignStyle ds;
  final void Function(BookInfo, Offset, Size) onBookTap;

  const BookWaterfallGrid({
    super.key,
    required this.books,
    required this.ds,
    required this.onBookTap,
  });

  @override
  Widget build(BuildContext context) {
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);

    if (concrete == DesignStyle.cupertino) {
      return LiquidGlassBookWaterfallGrid(
        books: books,
        ds: ds,
        onBookTap: onBookTap,
      );
    }

    return M3eBookWaterfallGrid(
      books: books,
      ds: ds,
      onBookTap: onBookTap,
    );
  }
}
