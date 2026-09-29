import 'package:flutter/cupertino.dart';
import 'package:material_ui/material_ui.dart';
import 'package:li_curriculum_table/core/presentation/styles/styles.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

IconData adaptiveIcon(
  dynamic style, {
  required IconData material,
  dynamic cupertino,
}) {
  if (cupertino != null) {
    final ds = style is DesignStyle ? style : null;
    final concrete = UiStyleRegistry.resolveConcreteStyle(ds);
    if (concrete == DesignStyle.cupertino) {
      return cupertino as IconData;
    }
  }
  return material;
}

/// Unified Adaptive icons for the app (Material 3 Expressive & iOS 26 Liquid Glass).
class AppIcons {
  const AppIcons._();

  // ─── Navigation (Tab Bar) ────────────────────────────────────────────────
  static IconData timetable([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.calendar_view_week,
    cupertino: CupertinoIcons.calendar_today,
  );
  static IconData timetableOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.calendar_view_week_outlined,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData classroom([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.meeting_room,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData classroomOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.meeting_room_outlined,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData grade([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.verified,
    cupertino: CupertinoIcons.chart_bar_fill,
  );
  static IconData gradeOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.verified_outlined,
    cupertino: CupertinoIcons.chart_bar,
  );
  static IconData exam([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.edit_note,
    cupertino: CupertinoIcons.pencil_ellipsis_rectangle,
  );
  static IconData examOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.edit_note_outlined,
    cupertino: CupertinoIcons.pencil_outline,
  );
  static IconData book([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.book_rounded,
    cupertino: CupertinoIcons.book_fill,
  );
  static IconData bookOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.book_outlined,
    cupertino: CupertinoIcons.book,
  );
  static IconData settings([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.settings,
    cupertino: CupertinoIcons.gear_alt_fill,
  );
  static IconData settingsOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.settings_outlined,
    cupertino: CupertinoIcons.gear_alt,
  );

  // ─── Actions ─────────────────────────────────────────────────────────────
  static IconData search([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.search_rounded,
    cupertino: CupertinoIcons.search,
  );
  static IconData refresh([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.refresh,
    cupertino: CupertinoIcons.arrow_clockwise,
  );
  static IconData syncIcon([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.sync_rounded,
    cupertino: CupertinoIcons.arrow_2_circlepath,
  );
  static IconData clear([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.clear_rounded,
    cupertino: CupertinoIcons.xmark,
  );
  static IconData arrowForward([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.arrow_forward_rounded,
    cupertino: CupertinoIcons.arrow_right,
  );
  static IconData chevronRight([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.chevron_right_rounded,
    cupertino: CupertinoIcons.chevron_right,
  );
  static IconData close([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.close,
    cupertino: CupertinoIcons.xmark,
  );

  // ─── Content ─────────────────────────────────────────────────────────────
  static IconData person([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.person_outline_rounded,
    cupertino: CupertinoIcons.person,
  );
  static IconData school([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.school,
    cupertino: CupertinoIcons.book,
  );
  static IconData location([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.location_on,
    cupertino: CupertinoIcons.location_fill,
  );
  static IconData locationOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.location_on_outlined,
    cupertino: CupertinoIcons.location,
  );
  static IconData time([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.access_time_filled,
    cupertino: CupertinoIcons.clock_fill,
  );
  static IconData calendar([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.calendar_today_rounded,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData star([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.star_rounded,
    cupertino: CupertinoIcons.star_fill,
  );
  static IconData starOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.star_outline,
    cupertino: CupertinoIcons.star,
  );
  static IconData bookmark([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.bookmark_outline_rounded,
    cupertino: CupertinoIcons.bookmark,
  );
  static IconData category([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.category_rounded,
    cupertino: CupertinoIcons.tag,
  );
  static IconData info([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.info_rounded,
    cupertino: CupertinoIcons.info_circle_fill,
  );
  static IconData lock([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.lock_outline,
    cupertino: CupertinoIcons.lock,
  );
  static IconData login([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.login_rounded,
    cupertino: CupertinoIcons.arrow_right_square,
  );
  static IconData menuBook([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.menu_book_rounded,
    cupertino: CupertinoIcons.book,
  );
  static IconData libraryBooks([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.library_books_rounded,
    cupertino: CupertinoIcons.collections,
  );
  static IconData place([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.place_rounded,
    cupertino: CupertinoIcons.placemark_fill,
  );
  static IconData business([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.business_rounded,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData bolt([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.bolt_rounded,
    cupertino: CupertinoIcons.bolt_fill,
  );
  static IconData seat([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.event_seat_outlined,
    cupertino: CupertinoIcons.person_2,
  );

  // ─── Settings ────────────────────────────────────────────────────────────
  static IconData vpnKey([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.vpn_key_outlined,
    cupertino: CupertinoIcons.lock_shield,
  );
  static IconData palette([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.palette_outlined,
    cupertino: CupertinoIcons.paintbrush,
  );
  static IconData colorLens([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.color_lens_outlined,
    cupertino: CupertinoIcons.color_filter,
  );
  static IconData viewWeek([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.view_week_rounded,
    cupertino: CupertinoIcons.slider_horizontal_3,
  );
  static IconData viewInAr([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.view_in_ar_rounded,
    cupertino: CupertinoIcons.cube,
  );
  static IconData viewWeekFilled([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.view_week_rounded,
    cupertino: CupertinoIcons.rectangle_grid_1x2_fill,
  );
  static IconData swapHoriz([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.swap_horiz_rounded,
    cupertino: CupertinoIcons.arrow_left_right,
  );
  static IconData lan([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.lan_outlined,
    cupertino: CupertinoIcons.wifi,
  );
  static IconData router([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.router_outlined,
    cupertino: CupertinoIcons.antenna_radiowaves_left_right,
  );
  static IconData numbers([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.numbers_outlined,
    cupertino: CupertinoIcons.number,
  );
  static IconData radar([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.radar_outlined,
    cupertino: CupertinoIcons.dot_radiowaves_left_right,
  );
  static IconData storage([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.storage_outlined,
    cupertino: CupertinoIcons.folder,
  );
  static IconData deleteSweep([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.delete_sweep_outlined,
    cupertino: CupertinoIcons.delete,
  );
  static IconData feedback([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.feedback_outlined,
    cupertino: CupertinoIcons.bubble_left,
  );
  static IconData markUnread([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.mark_as_unread_outlined,
    cupertino: CupertinoIcons.mail,
  );
  static IconData errorOutline([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.error_outline_rounded,
    cupertino: CupertinoIcons.exclamationmark_triangle,
  );
  static IconData cloudOff([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.cloud_off_rounded,
    cupertino: CupertinoIcons.exclamationmark_circle,
  );
  static IconData searchOff([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.search_off_rounded,
    cupertino: CupertinoIcons.search,
  );
  static IconData check([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.check_rounded,
    cupertino: CupertinoIcons.checkmark,
  );
  static IconData checkCircle([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.check_circle_rounded,
    cupertino: CupertinoIcons.checkmark_circle_fill,
  );
  static IconData calendarMonth([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.calendar_month_rounded,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData apartment([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.apartment_rounded,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData locationOn([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.location_on_rounded,
    cupertino: CupertinoIcons.location_fill,
  );
  static IconData analytics([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.analytics_rounded,
    cupertino: CupertinoIcons.chart_bar_fill,
  );
  static IconData stars([dynamic s]) => adaptiveIcon(
    s,
    material: Icons.stars_rounded,
    cupertino: CupertinoIcons.star_fill,
  );
}
