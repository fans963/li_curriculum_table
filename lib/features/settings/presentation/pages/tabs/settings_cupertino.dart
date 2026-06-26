import 'package:flutter/cupertino.dart';
import 'package:li_curriculum_table/core/di/service_locator.dart';
import 'package:li_curriculum_table/core/presentation/glass_scaffold.dart';

import 'package:li_curriculum_table/core/settings/domain/settings_repository.dart';
import 'package:li_curriculum_table/core/settings/presentation/settings_providers.dart';
import 'package:signals/signals_flutter.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:li_curriculum_table/core/services/update_service.dart';
import 'package:li_curriculum_table/core/presentation/adaptive_helpers.dart';
import 'package:li_curriculum_table/core/presentation/update_dialog.dart';
import 'package:li_curriculum_table/features/settings/presentation/pages/tabs/settings_sections.dart';
import 'package:li_curriculum_table/features/timetable/presentation/state/timetable_controller.dart';
import 'package:url_launcher/url_launcher.dart';

part 'sections/cupertino_theme_section.dart';
part 'sections/cupertino_behavior_section.dart';
part 'sections/cupertino_about_section.dart';

Widget buildSettingsCupertino({
  required BuildContext context,
  required dynamic state,
  required AppSettings settings,
  required TextEditingController usernameController,
  required TextEditingController passwordController,
  required bool mounted,
  required Future<void> Function() onClearCache,
}) {
  return GlassScaffold(
    title: '设置',
    trailingActions: [
      CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () => launchUrl(Uri.parse('mailto:fan@xuyan.me')),
        child: const Icon(CupertinoIcons.mail),
      ),
    ],
    slivers: [
      SliverList(
        delegate: SliverChildListDelegate([
          _Body(
            state: state,
            settings: settings,
            usernameController: usernameController,
            passwordController: passwordController,
            mounted: mounted,
            onClearCache: onClearCache,
          ),
        ]),
      ),
    ],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Body
// ═══════════════════════════════════════════════════════════════════════════

class _Body extends StatelessWidget {
  final dynamic state;
  final AppSettings settings;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final bool mounted;
  final Future<void> Function() onClearCache;

  const _Body({
    required this.state,
    required this.settings,
    required this.usernameController,
    required this.passwordController,
    required this.mounted,
    required this.onClearCache,
  });

  @override
  Widget build(BuildContext context) {
    final notifier = sl<SettingsController>();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _AccountCard(state: state, usernameController: usernameController, passwordController: passwordController),
            const SizedBox(height: 12),
            _SyncStatusCard(state: state),
            const SizedBox(height: 24),
            _SectionLabel('外观'),
            const SizedBox(height: 8),
            _ThemeCard(settings: settings, notifier: notifier),
            const SizedBox(height: 24),
            _SectionLabel('交互'),
            const SizedBox(height: 8),
            _InteractionCard(settings: settings, notifier: notifier),
            const SizedBox(height: 24),
            _SectionLabel('高级'),
            const SizedBox(height: 8),
            if (!kIsWeb) _ProxyCard(settings: settings, notifier: notifier, proxyController: TextEditingController()),
            if (!kIsWeb) const SizedBox(height: 8),
            _StorageCard(onClearCache: onClearCache, mounted: mounted),
            const SizedBox(height: 24),
            _SectionLabel('关于'),
            const SizedBox(height: 8),
            _AboutCard(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// iOS 26 Card Components
// ═══════════════════════════════════════════════════════════════════════════

/// Section label — iOS 26 style small caps header.
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.08,
            color: CupertinoColors.secondaryLabel.resolveFrom(context),
          ),
        ),
      ),
    );
  }
}

/// iOS 26 style card container with rounded corners and subtle border.
Widget _iosCard({required Widget child}) {
  return Container(
    decoration: BoxDecoration(
      color: CupertinoColors.secondarySystemGroupedBackground,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: CupertinoColors.separator.withValues(alpha: 0.2), width: 0.5),
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

/// iOS 26 style list tile inside a card with optional trailing widget.
Widget _iosTile(
  BuildContext context, {
  required IconData icon,
  required String title,
  String? subtitle,
  Widget? trailing,
  VoidCallback? onTap,
  Color? iconColor,
  bool showDivider = true,
}) {
  final cs = CupertinoColors.label.resolveFrom(context);
  final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor ?? secondary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 16, color: cs, fontWeight: FontWeight.w400)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle, style: TextStyle(fontSize: 13, color: secondary)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing
              else if (onTap != null)
                Icon(CupertinoIcons.chevron_forward, size: 16, color: CupertinoColors.tertiaryLabel.resolveFrom(context)),
            ],
          ),
        ),
      ),
      if (showDivider)
        Padding(
          padding: const EdgeInsets.only(left: 50),
          child: Container(height: 0.5, color: CupertinoColors.separator.resolveFrom(context).withValues(alpha: 0.3)),
        ),
    ],
  );
}
