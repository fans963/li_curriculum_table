import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const kDefaultAnimationDuration = Duration(milliseconds: 350);
const kDefaultAnimationCurve = Curves.easeInOutCubic;

bool get isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}