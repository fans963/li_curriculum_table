import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_style.dart';
import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';

/// Returns the appropriate icon for the current design style.
IconData adaptiveIcon(
  DesignStyle style, {
  required IconData material,
  required IconData cupertino,
}) {
  return AdaptiveStyle.isCupertino(style) ? cupertino : material;
}

/// Correct icon mappings verified against the actual CupertinoIcons constants.
class AppIcons {
  const AppIcons._();

  // ─── Navigation (Tab Bar) ────────────────────────────────────────────────
  static IconData timetable(DesignStyle s) => adaptiveIcon(s,
    material: Icons.calendar_view_week,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData timetableOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.calendar_view_week_outlined,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData classroom(DesignStyle s) => adaptiveIcon(s,
    material: Icons.meeting_room,
    cupertino: CupertinoIcons.person_3,
  );
  static IconData classroomOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.meeting_room_outlined,
    cupertino: CupertinoIcons.person_3,
  );
  static IconData grade(DesignStyle s) => adaptiveIcon(s,
    material: Icons.verified,
    cupertino: CupertinoIcons.checkmark_seal_fill,
  );
  static IconData gradeOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.verified_outlined,
    cupertino: CupertinoIcons.checkmark_seal,
  );
  static IconData exam(DesignStyle s) => adaptiveIcon(s,
    material: Icons.edit_note,
    cupertino: CupertinoIcons.pencil_outline,
  );
  static IconData examOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.edit_note_outlined,
    cupertino: CupertinoIcons.pencil_outline,
  );
  static IconData book(DesignStyle s) => adaptiveIcon(s,
    material: Icons.book_rounded,
    cupertino: CupertinoIcons.book_fill,
  );
  static IconData bookOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.book_outlined,
    cupertino: CupertinoIcons.book,
  );
  static IconData settings(DesignStyle s) => adaptiveIcon(s,
    material: Icons.settings,
    cupertino: CupertinoIcons.settings,
  );
  static IconData settingsOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.settings_outlined,
    cupertino: CupertinoIcons.settings,
  );

  // ─── Actions ─────────────────────────────────────────────────────────────
  static IconData search(DesignStyle s) => adaptiveIcon(s,
    material: Icons.search_rounded,
    cupertino: CupertinoIcons.search,
  );
  static IconData refresh(DesignStyle s) => adaptiveIcon(s,
    material: Icons.refresh,
    cupertino: CupertinoIcons.arrow_clockwise,
  );
  static IconData syncIcon(DesignStyle s) => adaptiveIcon(s,
    material: Icons.sync_rounded,
    cupertino: CupertinoIcons.arrow_2_circlepath,
  );
  static IconData clear(DesignStyle s) => adaptiveIcon(s,
    material: Icons.clear_rounded,
    cupertino: CupertinoIcons.xmark,
  );
  static IconData arrowForward(DesignStyle s) => adaptiveIcon(s,
    material: Icons.arrow_forward_rounded,
    cupertino: CupertinoIcons.arrow_right,
  );
  static IconData chevronRight(DesignStyle s) => adaptiveIcon(s,
    material: Icons.chevron_right_rounded,
    cupertino: CupertinoIcons.chevron_right,
  );
  static IconData close(DesignStyle s) => adaptiveIcon(s,
    material: Icons.close,
    cupertino: CupertinoIcons.xmark,
  );

  // ─── Content ─────────────────────────────────────────────────────────────
  static IconData person(DesignStyle s) => adaptiveIcon(s,
    material: Icons.person_outline_rounded,
    cupertino: CupertinoIcons.person,
  );
  static IconData personFilled(DesignStyle s) => adaptiveIcon(s,
    material: Icons.person,
    cupertino: CupertinoIcons.person_fill,
  );
  static IconData school(DesignStyle s) => adaptiveIcon(s,
    material: Icons.school,
    cupertino: CupertinoIcons.book,
  );
  static IconData location(DesignStyle s) => adaptiveIcon(s,
    material: Icons.location_on,
    cupertino: CupertinoIcons.location_fill,
  );
  static IconData locationOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.location_on_outlined,
    cupertino: CupertinoIcons.location,
  );
  static IconData time(DesignStyle s) => adaptiveIcon(s,
    material: Icons.access_time_filled,
    cupertino: CupertinoIcons.clock_fill,
  );
  static IconData timeOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.access_time,
    cupertino: CupertinoIcons.clock,
  );
  static IconData calendar(DesignStyle s) => adaptiveIcon(s,
    material: Icons.calendar_today_rounded,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData star(DesignStyle s) => adaptiveIcon(s,
    material: Icons.star_rounded,
    cupertino: CupertinoIcons.star_fill,
  );
  static IconData starOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.star_outline,
    cupertino: CupertinoIcons.star,
  );
  static IconData bookmark(DesignStyle s) => adaptiveIcon(s,
    material: Icons.bookmark_outline_rounded,
    cupertino: CupertinoIcons.bookmark,
  );
  static IconData bookmarkFilled(DesignStyle s) => adaptiveIcon(s,
    material: Icons.bookmark_rounded,
    cupertino: CupertinoIcons.bookmark_fill,
  );
  static IconData category(DesignStyle s) => adaptiveIcon(s,
    material: Icons.category_rounded,
    cupertino: CupertinoIcons.tag,
  );
  static IconData info(DesignStyle s) => adaptiveIcon(s,
    material: Icons.info_rounded,
    cupertino: CupertinoIcons.info_circle_fill,
  );
  static IconData lock(DesignStyle s) => adaptiveIcon(s,
    material: Icons.lock_outline,
    cupertino: CupertinoIcons.lock,
  );
  static IconData lockFilled(DesignStyle s) => adaptiveIcon(s,
    material: Icons.lock,
    cupertino: CupertinoIcons.lock_fill,
  );
  static IconData login(DesignStyle s) => adaptiveIcon(s,
    material: Icons.login_rounded,
    cupertino: CupertinoIcons.arrow_right_square,
  );
  static IconData menuBook(DesignStyle s) => adaptiveIcon(s,
    material: Icons.menu_book_rounded,
    cupertino: CupertinoIcons.book,
  );
  static IconData libraryBooks(DesignStyle s) => adaptiveIcon(s,
    material: Icons.library_books_rounded,
    cupertino: CupertinoIcons.collections,
  );
  static IconData place(DesignStyle s) => adaptiveIcon(s,
    material: Icons.place_rounded,
    cupertino: CupertinoIcons.placemark_fill,
  );
  static IconData business(DesignStyle s) => adaptiveIcon(s,
    material: Icons.business_rounded,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData bolt(DesignStyle s) => adaptiveIcon(s,
    material: Icons.bolt_rounded,
    cupertino: CupertinoIcons.bolt_fill,
  );
  static IconData seat(DesignStyle s) => adaptiveIcon(s,
    material: Icons.event_seat_outlined,
    cupertino: CupertinoIcons.person_2,
  );

  // ─── Settings ────────────────────────────────────────────────────────────
  static IconData vpnKey(DesignStyle s) => adaptiveIcon(s,
    material: Icons.vpn_key_outlined,
    cupertino: CupertinoIcons.lock_shield,
  );
  static IconData palette(DesignStyle s) => adaptiveIcon(s,
    material: Icons.palette_outlined,
    cupertino: CupertinoIcons.paintbrush,
  );
  static IconData colorLens(DesignStyle s) => adaptiveIcon(s,
    material: Icons.color_lens_outlined,
    cupertino: CupertinoIcons.color_filter,
  );
  static IconData viewWeek(DesignStyle s) => adaptiveIcon(s,
    material: Icons.view_week_outlined,
    cupertino: CupertinoIcons.rectangle_grid_1x2,
  );
  static IconData viewWeekFilled(DesignStyle s) => adaptiveIcon(s,
    material: Icons.view_week_rounded,
    cupertino: CupertinoIcons.rectangle_grid_1x2_fill,
  );
  static IconData swapHoriz(DesignStyle s) => adaptiveIcon(s,
    material: Icons.swap_horiz_rounded,
    cupertino: CupertinoIcons.arrow_left_right,
  );
  static IconData lan(DesignStyle s) => adaptiveIcon(s,
    material: Icons.lan_outlined,
    cupertino: CupertinoIcons.wifi,
  );
  static IconData router(DesignStyle s) => adaptiveIcon(s,
    material: Icons.router_outlined,
    cupertino: CupertinoIcons.antenna_radiowaves_left_right,
  );
  static IconData numbers(DesignStyle s) => adaptiveIcon(s,
    material: Icons.numbers_outlined,
    cupertino: CupertinoIcons.number,
  );
  static IconData radar(DesignStyle s) => adaptiveIcon(s,
    material: Icons.radar_outlined,
    cupertino: CupertinoIcons.dot_radiowaves_left_right,
  );
  static IconData storage(DesignStyle s) => adaptiveIcon(s,
    material: Icons.storage_outlined,
    cupertino: CupertinoIcons.folder,
  );
  static IconData deleteSweep(DesignStyle s) => adaptiveIcon(s,
    material: Icons.delete_sweep_outlined,
    cupertino: CupertinoIcons.delete,
  );
  static IconData feedback(DesignStyle s) => adaptiveIcon(s,
    material: Icons.feedback_outlined,
    cupertino: CupertinoIcons.bubble_left,
  );
  static IconData markUnread(DesignStyle s) => adaptiveIcon(s,
    material: Icons.mark_as_unread_outlined,
    cupertino: CupertinoIcons.mail,
  );
  static IconData systemUpdate(DesignStyle s) => adaptiveIcon(s,
    material: Icons.system_update_rounded,
    cupertino: CupertinoIcons.arrow_down_circle,
  );
  static IconData errorOutline(DesignStyle s) => adaptiveIcon(s,
    material: Icons.error_outline_rounded,
    cupertino: CupertinoIcons.exclamationmark_triangle,
  );
  static IconData cloudOff(DesignStyle s) => adaptiveIcon(s,
    material: Icons.cloud_off_rounded,
    cupertino: CupertinoIcons.exclamationmark_circle,
  );
  static IconData searchOff(DesignStyle s) => adaptiveIcon(s,
    material: Icons.search_off_rounded,
    cupertino: CupertinoIcons.search,
  );
  static IconData check(DesignStyle s) => adaptiveIcon(s,
    material: Icons.check_rounded,
    cupertino: CupertinoIcons.checkmark,
  );
  static IconData checkCircle(DesignStyle s) => adaptiveIcon(s,
    material: Icons.check_circle_rounded,
    cupertino: CupertinoIcons.checkmark_circle_fill,
  );
  static IconData closeCircle(DesignStyle s) => adaptiveIcon(s,
    material: Icons.close_rounded,
    cupertino: CupertinoIcons.xmark_circle_fill,
  );
  static IconData calendarMonth(DesignStyle s) => adaptiveIcon(s,
    material: Icons.calendar_month_rounded,
    cupertino: CupertinoIcons.calendar,
  );
  static IconData apartment(DesignStyle s) => adaptiveIcon(s,
    material: Icons.apartment_rounded,
    cupertino: CupertinoIcons.building_2_fill,
  );
  static IconData locationOn(DesignStyle s) => adaptiveIcon(s,
    material: Icons.location_on_rounded,
    cupertino: CupertinoIcons.location_fill,
  );
  static IconData analytics(DesignStyle s) => adaptiveIcon(s,
    material: Icons.analytics_rounded,
    cupertino: CupertinoIcons.chart_bar_fill,
  );
  static IconData stars(DesignStyle s) => adaptiveIcon(s,
    material: Icons.stars_rounded,
    cupertino: CupertinoIcons.star_fill,
  );
  static IconData android(DesignStyle s) => adaptiveIcon(s,
    material: Icons.android,
    cupertino: CupertinoIcons.device_phone_portrait,
  );
  static IconData apple(DesignStyle s) => adaptiveIcon(s,
    material: Icons.apple,
    cupertino: CupertinoIcons.device_phone_portrait,
  );
  static IconData phone(DesignStyle s) => adaptiveIcon(s,
    material: Icons.phone_android,
    cupertino: CupertinoIcons.device_phone_portrait,
  );
  static IconData keyboard(DesignStyle s) => adaptiveIcon(s,
    material: Icons.keyboard,
    cupertino: CupertinoIcons.keyboard,
  );
  static IconData fullscreen(DesignStyle s) => adaptiveIcon(s,
    material: Icons.fullscreen,
    cupertino: CupertinoIcons.fullscreen,
  );
  static IconData fullscreenExit(DesignStyle s) => adaptiveIcon(s,
    material: Icons.fullscreen_exit,
    cupertino: CupertinoIcons.fullscreen_exit,
  );
  static IconData minimize(DesignStyle s) => adaptiveIcon(s,
    material: Icons.minimize,
    cupertino: CupertinoIcons.minus,
  );
}
