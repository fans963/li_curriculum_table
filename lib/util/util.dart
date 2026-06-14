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

/// Spring curve for selection/toggle animations — bouncy feel.
const kSpringCurve = Curves.elasticOut;

/// Emphasized easing for attention-grabbing transitions.
const kEmphasizedCurve = Curves.easeOutBack;

// ─── Platform check ────────────────────────────────────────────────────────

bool get isDesktop {
  if (kIsWeb) return false;
  return defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.windows;
}
