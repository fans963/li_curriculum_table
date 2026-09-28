import 'package:material_ui/material_ui.dart';

IconData adaptiveIcon(
  dynamic style, {
  required IconData material,
  dynamic cupertino,
}) {
  return material;
}

/// Unified Material 3 icons for the app.
class AppIcons {
  const AppIcons._();

  // ─── Navigation (Tab Bar) ────────────────────────────────────────────────
  static IconData timetable([dynamic _]) => Icons.calendar_view_week;
  static IconData timetableOutline([dynamic _]) => Icons.calendar_view_week_outlined;
  static IconData classroom([dynamic _]) => Icons.meeting_room;
  static IconData classroomOutline([dynamic _]) => Icons.meeting_room_outlined;
  static IconData grade([dynamic _]) => Icons.verified;
  static IconData gradeOutline([dynamic _]) => Icons.verified_outlined;
  static IconData exam([dynamic _]) => Icons.edit_note;
  static IconData examOutline([dynamic _]) => Icons.edit_note_outlined;
  static IconData book([dynamic _]) => Icons.book_rounded;
  static IconData bookOutline([dynamic _]) => Icons.book_outlined;
  static IconData settings([dynamic _]) => Icons.settings;
  static IconData settingsOutline([dynamic _]) => Icons.settings_outlined;

  // ─── Actions ─────────────────────────────────────────────────────────────
  static IconData search([dynamic _]) => Icons.search_rounded;
  static IconData refresh([dynamic _]) => Icons.refresh;
  static IconData syncIcon([dynamic _]) => Icons.sync_rounded;
  static IconData clear([dynamic _]) => Icons.clear_rounded;
  static IconData arrowForward([dynamic _]) => Icons.arrow_forward_rounded;
  static IconData chevronRight([dynamic _]) => Icons.chevron_right_rounded;
  static IconData close([dynamic _]) => Icons.close;

  // ─── Content ─────────────────────────────────────────────────────────────
  static IconData person([dynamic _]) => Icons.person_outline_rounded;
  static IconData school([dynamic _]) => Icons.school;
  static IconData location([dynamic _]) => Icons.location_on;
  static IconData locationOutline([dynamic _]) => Icons.location_on_outlined;
  static IconData time([dynamic _]) => Icons.access_time_filled;
  static IconData calendar([dynamic _]) => Icons.calendar_today_rounded;
  static IconData star([dynamic _]) => Icons.star_rounded;
  static IconData starOutline([dynamic _]) => Icons.star_outline;
  static IconData bookmark([dynamic _]) => Icons.bookmark_outline_rounded;
  static IconData category([dynamic _]) => Icons.category_rounded;
  static IconData info([dynamic _]) => Icons.info_rounded;
  static IconData lock([dynamic _]) => Icons.lock_outline;
  static IconData login([dynamic _]) => Icons.login_rounded;
  static IconData menuBook([dynamic _]) => Icons.menu_book_rounded;
  static IconData libraryBooks([dynamic _]) => Icons.library_books_rounded;
  static IconData place([dynamic _]) => Icons.place_rounded;
  static IconData business([dynamic _]) => Icons.business_rounded;
  static IconData bolt([dynamic _]) => Icons.bolt_rounded;
  static IconData seat([dynamic _]) => Icons.event_seat_outlined;

  // ─── Settings ────────────────────────────────────────────────────────────
  static IconData vpnKey([dynamic _]) => Icons.vpn_key_outlined;
  static IconData palette([dynamic _]) => Icons.palette_outlined;
  static IconData colorLens([dynamic _]) => Icons.color_lens_outlined;
  static IconData viewWeek([dynamic _]) => Icons.view_week_rounded;
  static IconData viewInAr([dynamic _]) => Icons.view_in_ar_rounded;
  static IconData viewWeekFilled([dynamic _]) => Icons.view_week_rounded;
  static IconData swapHoriz([dynamic _]) => Icons.swap_horiz_rounded;
  static IconData lan([dynamic _]) => Icons.lan_outlined;
  static IconData router([dynamic _]) => Icons.router_outlined;
  static IconData numbers([dynamic _]) => Icons.numbers_outlined;
  static IconData radar([dynamic _]) => Icons.radar_outlined;
  static IconData storage([dynamic _]) => Icons.storage_outlined;
  static IconData deleteSweep([dynamic _]) => Icons.delete_sweep_outlined;
  static IconData feedback([dynamic _]) => Icons.feedback_outlined;
  static IconData markUnread([dynamic _]) => Icons.mark_as_unread_outlined;
  static IconData errorOutline([dynamic _]) => Icons.error_outline_rounded;
  static IconData cloudOff([dynamic _]) => Icons.cloud_off_rounded;
  static IconData searchOff([dynamic _]) => Icons.search_off_rounded;
  static IconData check([dynamic _]) => Icons.check_rounded;
  static IconData checkCircle([dynamic _]) => Icons.check_circle_rounded;
  static IconData calendarMonth([dynamic _]) => Icons.calendar_month_rounded;
  static IconData apartment([dynamic _]) => Icons.apartment_rounded;
  static IconData locationOn([dynamic _]) => Icons.location_on_rounded;
  static IconData analytics([dynamic _]) => Icons.analytics_rounded;
  static IconData stars([dynamic _]) => Icons.stars_rounded;
}
