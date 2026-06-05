import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// ─── M3 Expressive Motion Tokens ───────────────────────────────────────────
// Spring-based physics for bouncier, more expressive micro-interactions.
// Reference: m3.material.io/styles/motion/easing-and-duration/tokens-specs

/// Default animation duration — M3 Expressive medium2 (300ms).
const kDefaultAnimationDuration = Duration(milliseconds: 300);

/// Default animation curve — spring-based for expressive feel.
const kDefaultAnimationCurve = Curves.easeOutCubic;

/// Quick interaction duration — iOS 26 recommends <200ms for taps/presses.
const kInteractionDuration = Duration(milliseconds: 150);

/// Medium transition — M3 Expressive medium3 (350ms).
const kMediumTransitionDuration = Duration(milliseconds: 350);

/// Large transform — M3 Expressive long1 (450ms), e.g. card → full screen.
const kLargeTransformDuration = Duration(milliseconds: 450);

/// Spring curve for selection/toggle animations — bouncy feel.
const kSpringCurve = Curves.elasticOut;

/// Emphasized easing for attention-grabbing transitions.
const kEmphasizedCurve = Curves.easeOutBack;

// ─── M3 Expressive Shape Tokens ────────────────────────────────────────────
// Corner radii: large=20dp, xLarge=32dp, xxLarge=48dp, full=100%

const double kShapeSmall = 12;
const double kShapeMedium = 16;
const double kShapeLarge = 20;
const double kShapeXLarge = 28;
const double kShapeXXLarge = 32;

// ─── Platform check ────────────────────────────────────────────────────────

bool get isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}
